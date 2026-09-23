#!/usr/bin/env node
// Hue Entertainment streaming — 50Hz DTLS push.
//
// Commands:
//   setup              create/verify entertainment config, list channels
//   rainbow [seconds]  rainbow chase, hue offset by light X-position
//   matrix  [seconds]  green "rain" drops falling along Y-axis
//   daemon [ambient]   long-running: holds DTLS, listens for UDP pulse events
//   trigger pulse x y z [r g b dur] fire a spatial burst (used by Hammerspoon)
//   trigger ambient <name>                switch daemon's ambient animation
//   trigger quit                          shut down daemon
//   stop                                  force-deactivate any active stream
//
// Spatial layout: reads ~/.local/share/hue/positions.json keyed by light name
// -> { "Desk Lamp": [-0.8, 0.5, 0], ... }  (x in -1..1, y up, z forward)

const { dtls } = require('node-dtls-client');
const { Agent, setGlobalDispatcher } = require('undici');
const dgram = require('dgram');
const fs = require('fs');
const os = require('os');
const path = require('path');

// Bridge uses a self-signed cert — trust it for this process only.
setGlobalDispatcher(new Agent({ connect: { rejectUnauthorized: false } }));

const DAEMON_PORT = 9999;

// One-shot flash / restore timings (ms). The bridge is REST-rate-limited and
// needs a beat to settle after an entertainment session deactivates.
const RESTORE_SETTLE_MS = 300;      // pause after deactivate before re-asserting
const RESTORE_TRANSITION_MS = 250;  // ease the restore back rather than snap it
const LIGHT_PUT_GAP_MS = 60;        // spacing between per-light REST PUTs

const BRIDGE = process.env.HUE_BRIDGE_IP;
const KEY = process.env.HUE_APP_KEY;
const CLIENT_KEY = process.env.HUE_CLIENT_KEY;
const CONFIG_NAME = 'ejfox-stream';
// Comma-separated room names to exclude from the Entertainment group.
// Case-insensitive. Lights in these rooms stay on regular Hue API control
// instead of being blanked by the daemon's ambient.
//
// HARD FLOOR: these rooms are ALWAYS excluded, in code, regardless of env.
// "pamaras room" = gf's office — her lights must never be flashed. This lives
// in the repo (not just ~/.env) so the guarantee survives a fresh checkout,
// a rebuilt ~/.env, or a `setup` run from a shell that didn't source it.
// HUE_STREAM_EXCLUDE_ROOMS can ADD rooms; it can never remove the floor.
const EXCLUDE_ROOMS_FLOOR = ['pamaras room'];
const EXCLUDE_ROOMS = [...new Set([
  ...EXCLUDE_ROOMS_FLOOR,
  ...(process.env.HUE_STREAM_EXCLUDE_ROOMS || '')
    .split(',').map(s => s.trim().toLowerCase()).filter(Boolean),
])];
const POS_FILE = path.join(os.homedir(), '.local/share/hue/positions.json');
const CONFIG_FILE = path.join(os.homedir(), '.config/hue-key/config.json');

if (!BRIDGE || !KEY || !CLIENT_KEY) {
  console.error('error: HUE_BRIDGE_IP, HUE_APP_KEY, HUE_CLIENT_KEY must be set (see ~/.env)');
  process.exit(1);
}

// The Hue CLIP v2 REST client for one bridge. Everything that talks to the
// bridge goes through `bridge.api(...)`; the module-level `api` below is a thin
// alias so existing callers keep working unchanged.
class Bridge {
  constructor(ip, appKey) {
    this.ip = ip;
    this.appKey = appKey;
  }
  async api(method, pathStr, body) {
    const res = await fetch(`https://${this.ip}/clip/v2${pathStr}`, {
      method,
      headers: { 'hue-application-key': this.appKey, 'Content-Type': 'application/json' },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    try { return JSON.parse(text); } catch { return text; }
  }
  // Is the bridge answering on the LAN right now? (false when VPN blocks the LAN
  // or the bridge moved/off — lets callers degrade instead of hanging.)
  async reachable() {
    try { return Array.isArray((await this.api('GET', '/resource/bridge'))?.data); }
    catch { return false; }
  }
}

const bridge = new Bridge(BRIDGE, KEY);
const api = (method, pathStr, body) => bridge.api(method, pathStr, body);

function loadPositions() {
  try { return JSON.parse(fs.readFileSync(POS_FILE, 'utf8')); }
  catch { return {}; }
}

function loadConfig() {
  try { return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8')); }
  catch { return { mode: 'uniform', targets: [], echo: { enabled: false, layers: [] } }; }
}

function resolveTargets(patterns, state) {
  if (!patterns || patterns.length === 0) return null;
  const pats = patterns.map(p => String(p).toLowerCase());
  const targetSet = new Set();
  const N = state.channelNames.length;
  for (let i = 0; i < N; i++) {
    const nameHit = pats.some(p => state.channelNames[i].includes(p));
    const roomHit = pats.some(p => (state.channelRooms[i] || '').includes(p));
    if (nameHit || roomHit) targetSet.add(i);
  }
  return targetSet.size > 0 ? targetSet : null;
}

function ringPosition(i, n) {
  const a = (i / n) * Math.PI * 2;
  return [Math.cos(a) * 0.8, 0, Math.sin(a) * 0.8];
}

async function ensureConfig() {
  const ent = (await api('GET', '/resource/entertainment')).data.filter(e => e.renderer);
  const lights = (await api('GET', '/resource/light')).data;
  const rooms = (await api('GET', '/resource/room')).data;

  // Map device → Hue room name
  const deviceToRoom = {};
  for (const room of rooms) {
    for (const child of (room.children || [])) {
      if (child.rtype === 'device') deviceToRoom[child.rid] = room.metadata.name;
    }
  }

  const streamers = ent.map(e => {
    const ownerDeviceId = e.owner.rid;
    const light = lights.find(l => l.owner?.rid === ownerDeviceId);
    return {
      entId: e.id,
      lightId: light?.id,
      name: light?.metadata?.name || '?',
      room: deviceToRoom[ownerDeviceId] || '',
    };
  }).filter(s => s.lightId && !EXCLUDE_ROOMS.includes((s.room || '').toLowerCase()));

  const configs = (await api('GET', '/resource/entertainment_configuration')).data;
  let cfg = configs.find(c => c.metadata?.name === CONFIG_NAME);

  if (!cfg) {
    const positions = loadPositions();
    const withPos = streamers.map((s, i) => {
      const p = positions[s.name] || ringPosition(i, streamers.length);
      return { s, pos: { x: p[0], y: p[1], z: p[2] } };
    });
    const body = {
      type: 'entertainment_configuration',
      metadata: { name: CONFIG_NAME },
      configuration_type: '3dspace',
      locations: {
        service_locations: withPos.map(w => ({
          service: { rid: w.s.entId, rtype: 'entertainment' },
          positions: [w.pos],
          equalization_factor: 1,
        })),
      },
    };
    const result = await api('POST', '/resource/entertainment_configuration', body);
    if (result.errors?.length) {
      console.error('config create failed:', JSON.stringify(result.errors, null, 2));
      process.exit(1);
    }
    const newId = result.data[0].rid;
    cfg = (await api('GET', `/resource/entertainment_configuration/${newId}`)).data[0];
    console.log(`created entertainment config: ${newId}`);
  }

  // Filter streamers to only the lights actually in this config's channels
  const cfgEntIds = new Set();
  for (const ch of cfg.channels) {
    for (const member of ch.members) {
      cfgEntIds.add(member.service.rid);
    }
  }

  // Build ordered list matching channel order
  const cfgStreamers = cfg.channels.map(ch => {
    const entId = ch.members[0]?.service?.rid;
    return streamers.find(s => s.entId === entId) || { entId, lightId: null, name: '?', room: '' };
  });

  return { cfg, streamers: cfgStreamers };
}

async function activate(cfgId) {
  // Always do a fresh activate — bridge needs it right before DTLS
  const check = await api('GET', `/resource/entertainment_configuration/${cfgId}`);
  if (check.data?.[0]?.status === 'active') {
    console.log('[activate] stopping first for fresh activation...');
    await api('PUT', `/resource/entertainment_configuration/${cfgId}`, { action: 'stop' });
    await new Promise(r => setTimeout(r, 1000));
  }
  const result = await api('PUT', `/resource/entertainment_configuration/${cfgId}`, { action: 'start' });
  if (result.errors?.length) throw new Error('activate: ' + JSON.stringify(result.errors));
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 150));
    const cur = await api('GET', `/resource/entertainment_configuration/${cfgId}`);
    if (cur.data?.[0]?.status === 'active') {
      await new Promise(r => setTimeout(r, 2000));  // let bridge settle before DTLS
      return;
    }
  }
  throw new Error('activate: bridge never reported active');
}

async function deactivate(cfgId) {
  try { await api('PUT', `/resource/entertainment_configuration/${cfgId}`, { action: 'stop' }); }
  catch (e) { /* best-effort */ }
}

// Capture the exact live state of the given lights *before* entertainment
// hijacks them. The bridge's own restore-on-deactivate is unreliable — it
// tends to snap back to the last scene/default rather than the color that was
// actually showing — so we snapshot here and re-assert it ourselves after.
async function snapshotLights(ids) {
  if (!ids.length) return [];
  const r = await api('GET', '/resource/light');
  const byId = new Map((r.data || []).map(l => [l.id, l]));
  const snap = [];
  for (const id of ids) {
    const l = byId.get(id);
    if (!l) continue;
    const s = { id, on: l.on?.on ?? true };
    if (typeof l.dimming?.brightness === 'number') s.brightness = l.dimming.brightness;
    if (l.color?.xy) s.xy = { x: l.color.xy.x, y: l.color.xy.y };
    else if (l.color_temperature?.mirek) s.mirek = l.color_temperature.mirek;
    snap.push(s);
  }
  return snap;
}

// Build the REST body that re-asserts one snapshotted light. transitionMs=0 snaps
// instantly (scoped desk flash cleanup); >0 eases it (post-entertainment restore).
function buildLightRestoreBody(s, transitionMs) {
  const body = { on: { on: s.on } };
  if (s.on) {
    if (typeof s.brightness === 'number') body.dimming = { brightness: s.brightness };
    if (s.xy) body.color = { xy: s.xy };
    else if (s.mirek) body.color_temperature = { mirek: s.mirek };
    body.dynamics = { duration: transitionMs };
  }
  return body;
}

// Re-assert a prior snapshot via the regular API after the entertainment
// session closes. Short transition so it eases back rather than snapping.
async function restoreLights(snap) {
  if (!snap || !snap.length) return;
  await new Promise(r => setTimeout(r, RESTORE_SETTLE_MS));  // settle post-deactivate
  for (const s of snap) {
    try { await api('PUT', `/resource/light/${s.id}`, buildLightRestoreBody(s, RESTORE_TRANSITION_MS)); }
    catch { /* best-effort per light */ }
    await new Promise(r => setTimeout(r, LIGHT_PUT_GAP_MS));  // stay under PUT rate limit
  }
}

function buildFrame(cfgId, seq, channelColors) {
  const header = Buffer.alloc(52);
  header.write('HueStream', 0, 'ascii');
  header[9] = 2;
  header[10] = 0;
  header[11] = seq & 0xff;
  header[14] = 0;  // color space: RGB
  header.write(cfgId, 16, 'ascii');

  const payload = Buffer.alloc(7 * channelColors.length);
  channelColors.forEach(([id, r, g, b], i) => {
    payload[i * 7] = id;
    payload.writeUInt16BE(Math.round(r * 65535), i * 7 + 1);
    payload.writeUInt16BE(Math.round(g * 65535), i * 7 + 3);
    payload.writeUInt16BE(Math.round(b * 65535), i * 7 + 5);
  });
  return Buffer.concat([header, payload]);
}

function openSocket() {
  return new Promise((resolve, reject) => {
    const psk = {};
    psk[KEY] = Buffer.from(CLIENT_KEY, 'hex');
    const socket = dtls.createSocket({
      type: 'udp4',
      address: BRIDGE,
      port: 2100,
      psk,
      timeout: 15000,
      ciphers: ['TLS_PSK_WITH_AES_128_GCM_SHA256'],
    });
    socket.on('connected', () => resolve(socket));
    socket.on('error', (e) => reject(e));
  });
}

// ─── Animations ────────────────────────────────────────────────────────────

function hsv(h, s, v) {
  const c = v * s;
  const hp = (h % 1) * 6;
  const x = c * (1 - Math.abs((hp % 2) - 1));
  const m = v - c;
  let [r, g, b] = [0, 0, 0];
  if (hp < 1) [r, g, b] = [c, x, 0];
  else if (hp < 2) [r, g, b] = [x, c, 0];
  else if (hp < 3) [r, g, b] = [0, c, x];
  else if (hp < 4) [r, g, b] = [0, x, c];
  else if (hp < 5) [r, g, b] = [x, 0, c];
  else [r, g, b] = [c, 0, x];
  return [r + m, g + m, b + m];
}

function rainbow(channels) {
  return (i, t) => {
    const x = channels[i].position.x;
    const h = (t * 0.25 + (x + 1) / 2) % 1;
    return hsv(h, 1, 0.7);
  };
}

function matrix(channels) {
  const drops = channels.map((_, i) => ({
    period: 2 + (i % 3) * 0.7,
    offset: (i * 0.37) % 1,
  }));
  return (i, t) => {
    const { y } = channels[i].position;
    const d = drops[i];
    const phase = ((t / d.period) + d.offset) % 1;
    const dropY = 1 - phase * 2.2;
    const delta = dropY - y;
    const trail = delta > 0 ? Math.max(0, 1 - delta * 1.5) : Math.max(0, 1 + delta * 0.8) * 0.15;
    const bri = trail * 0.9;
    return [bri * 0.05, bri, bri * 0.4];
  };
}

function dark() { return () => [0, 0, 0]; }

// Usable working-light baseline — warm white at ~70%. Pulses add a small bump
// on top (see SUBTLE_MULT in Hammerspoon init.lua). Override via env.
function warm() {
  const raw = process.env.HUE_STREAM_WARM || '0.78,0.55,0.32';
  const rgb = raw.split(',').map(parseFloat);
  const [r, g, b] = (rgb.length === 3 && rgb.every(v => v >= 0 && v <= 1)) ? rgb : [0.78, 0.55, 0.32];
  return () => [r, g, b];
}

// ─── HCL (CIELAB LCh) color blending ────────────────────────────────────────
// Perceptual easing lives here: we interpolate in LCh so a red→blue fade sweeps
// through vivid hues instead of muddy gray (which is what naive RGB lerp gives).

function srgbToLin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
function linToSrgb(c) { return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055; }

function rgbToLch([r, g, b]) {
  const R = srgbToLin(r), G = srgbToLin(g), B = srgbToLin(b);
  const x = R * 0.4124564 + G * 0.3575761 + B * 0.1804375;
  const y = R * 0.2126729 + G * 0.7151522 + B * 0.0721750;
  const z = R * 0.0193339 + G * 0.1191920 + B * 0.9503041;
  const f = t => t > 0.008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116;
  const fx = f(x / 0.95047), fy = f(y / 1.0), fz = f(z / 1.08883);
  const L = 116 * fy - 16, a = 500 * (fx - fy), bb = 200 * (fy - fz);
  const C = Math.hypot(a, bb);
  const H = Math.atan2(bb, a); // radians
  return [L, C, H];
}

function lchToRgb([L, C, H]) {
  const a = C * Math.cos(H), bb = C * Math.sin(H);
  const fy = (L + 16) / 116, fx = fy + a / 500, fz = fy - bb / 200;
  const fi = t => { const t3 = t * t * t; return t3 > 0.008856 ? t3 : (t - 16 / 116) / 7.787; };
  const x = fi(fx) * 0.95047, y = fi(fy) * 1.0, z = fi(fz) * 1.08883;
  const R = x * 3.2404542 + y * -1.5371385 + z * -0.4985314;
  const G = x * -0.9692660 + y * 1.8760108 + z * 0.0415560;
  const B = x * 0.0556434 + y * -0.2040259 + z * 1.0572252;
  const clamp = v => Math.min(1, Math.max(0, linToSrgb(v)));
  return [clamp(R), clamp(G), clamp(B)];
}

// Exponential ease from `cur` toward `target` by fraction `a`, blended in LCh.
// Hue takes the shortest angular path; a chroma-less endpoint borrows the
// other's hue so fades to/from black or gray don't spin through random hues.
function easeLch(cur, target, a) {
  const c1 = rgbToLch(cur), c2 = rgbToLch(target);
  let [L1, C1, H1] = c1, [L2, C2, H2] = c2;
  if (C1 < 1e-3) H1 = H2;
  if (C2 < 1e-3) H2 = H1;
  let dH = H2 - H1;
  while (dH > Math.PI) dH -= 2 * Math.PI;
  while (dH < -Math.PI) dH += 2 * Math.PI;
  const L = L1 + (L2 - L1) * a;
  const C = C1 + (C2 - C1) * a;
  const H = H1 + dH * a;
  return lchToRgb([L, C, H]);
}

// Screen-sync ambient: an external sampler pushes `state.screen.zones`
// (left→right color bands from the primary display) via {type:'screen'}.
// Each channel maps its x-position to a band and eases toward it in HCL at
// 50Hz — so sampling can be slow while the lights stay silky.
function screen(channels, state) {
  const alpha = (() => { const v = parseFloat(process.env.HUE_SCREEN_EASE); return v > 0 && v <= 1 ? v : 0.16; })();
  return (i, t, ch) => {
    const sc = state.screen || {};
    const zones = (sc.zones && sc.zones.length) ? sc.zones : null;
    let target;
    if (!zones) {
      target = [0, 0, 0];
    } else {
      const x = (ch && ch.position) ? ch.position.x : 0;
      const nz = zones.length;
      let zi = Math.floor(((x + 1) / 2) * nz);
      if (zi < 0) zi = 0; if (zi >= nz) zi = nz - 1;
      target = zones[zi] || [0, 0, 0];
    }
    const cur = sc.current[i] || [0, 0, 0];
    const next = easeLch(cur, target, alpha);
    sc.current[i] = next;
    return next;
  };
}

const AMBIENT_FNS = { rainbow, matrix, dark, warm, screen };

// ─── One-shot commands ────────────────────────────────────────────────────

async function cmdSetup() {
  const { cfg, streamers } = await ensureConfig();
  console.log(`\nentertainment config: ${cfg.id}`);
  console.log(`${cfg.channels.length} channels:`);
  cfg.channels.forEach((c, i) => {
    const name = streamers[i]?.name || '?';
    const p = c.position;
    console.log(`  ch${c.channel_id}  (${p.x.toFixed(2)}, ${p.y.toFixed(2)}, ${p.z.toFixed(2)})  ${name}`);
  });
  console.log(`\nedit ${POS_FILE} to customize positions, then delete the config and re-run setup.`);
}

async function cmdRun(animName, durationSec) {
  const { cfg } = await ensureConfig();
  const build = AMBIENT_FNS[animName];
  if (!build) { console.error('unknown animation'); process.exit(1); }
  const colorAt = build(cfg.channels);
  console.log(`streaming ${animName} for ${durationSec}s...`);
  await activate(cfg.id);
  const socket = await openSocket();
  const start = Date.now();
  let seq = 0;
  try {
    await new Promise((resolve) => {
      const cleanup = () => { clearInterval(tick); try { socket.close(); } catch {} resolve(); };
      process.once('SIGINT', cleanup);
      const tick = setInterval(() => {
        const t = (Date.now() - start) / 1000;
        if (t >= durationSec) return cleanup();
        const colors = cfg.channels.map((_, i) => {
          const [r, g, b] = colorAt(i, t);
          return [i, r, g, b];
        });
        try { socket.send(buildFrame(cfg.id, seq++, colors)); } catch { cleanup(); }
      }, 20);
    });
  } finally { await deactivate(cfg.id); }
  console.log('done.');
}

async function cmdStop() {
  const configs = (await api('GET', '/resource/entertainment_configuration')).data;
  for (const c of configs) {
    if (c.status === 'active') {
      await deactivate(c.id);
      console.log(`stopped: ${c.metadata?.name || c.id}`);
    }
  }
}

// ─── One-shot event flash ──────────────────────────────────────────────────
// Opens a short entertainment session, plays one grammar envelope, closes.
// The bridge restores the lights' prior state on deactivate — so scenes
// (sun-synced wake-up etc.) survive; no standing daemon required.

// Loads the shared flash grammar (desk-flash-patterns.json — the same file the
// bash side reads via flash-lib.sh) and resolves an event name to concrete flash
// parameters. Read-only; falls back to a soft teal blip for unknown events.
class Grammar {
  constructor(file = path.join(os.homedir(), '.dotfiles/lib/desk-flash-patterns.json')) {
    try { this.data = JSON.parse(fs.readFileSync(file, 'utf8')); }
    catch { this.data = { palette: {}, events: {} }; }
  }
  // → { rgb: [0..1,0..1,0..1], peak, segs, scope }
  event(name) {
    const ev = this.data.events?.[name] || {};
    const rgb255 = this.data.palette?.[ev.color] || [110, 237, 247];
    return {
      rgb: rgb255.map(v => v / 255),
      peak: ev.peak ?? 1.0,
      segs: Array.isArray(ev.segs) ? ev.segs : [[0.4, true]],
      scope: Array.isArray(ev.scope) ? ev.scope : [],
    };
  }
}

// Forensic log: record a Hue flash + who triggered it (view with `flashlog`).
// Fire-and-forget; never blocks or breaks the flash.
function logFlash(mode, eventName) {
  try {
    const { spawn } = require('child_process');
    spawn(path.join(os.homedir(), '.dotfiles/bin/flash-log'),
      [`hue-stream:${mode}`, eventName || ''],
      { detached: true, stdio: 'ignore' }).unref();
  } catch { /* best-effort */ }
}

async function cmdFlash(eventName = 'done') {
  logFlash('flash', eventName);
  // never fight a running daemon for the session — it renders flashes itself
  // (checked again here in case the caller didn't)
  const { rgb, peak, segs, scope } = new Grammar().event(eventName);

  // Scoped events (done/fyi) only ping the desk lights. Do that over the plain
  // REST API — no whole-room entertainment takeover, no DTLS wedge risk, and
  // every other light in the house is left exactly as it was. Whole-room washes
  // (needs/error, no scope) fall through to the entertainment session below.
  if (scope.length) return cmdFlashRest(rgb, peak, segs, scope);

  // DTLS wedge guard: min 8s between one-shot sessions, one at a time
  const stamp = '/tmp/hue-flash-once.last';
  try {
    if ((Date.now() - fs.statSync(stamp).mtimeMs) / 1000 < 8) return;
  } catch {}
  fs.writeFileSync(stamp, String(process.pid));

  const env = (t) => {
    for (const [d, lit] of segs) {
      if (t < d) return lit ? peak * Math.sin(Math.PI * (t / d)) : 0;
      t -= d;
    }
    return null; // pattern over
  };

  const { cfg, streamers } = await ensureConfig();
  // Snapshot the live color of every light this flash will touch, BEFORE the
  // entertainment session freezes their REST state — so we can restore exactly
  // what was showing (screen-sync color, scene, manual set) afterward.
  const snap = await snapshotLights(streamers.map(s => s.lightId).filter(Boolean));
  // deactivate in finally no matter where we die — a failed DTLS handshake
  // must never leave the config active (that blocks bridge scenes, the very
  // thing one-shot sessions exist to avoid)
  try {
    await activate(cfg.id);
    const socket = await openSocket();
    const start = Date.now();
    let seq = 0;
    await new Promise((resolve) => {
      const cleanup = () => { clearInterval(tick); try { socket.close(); } catch {} resolve(); };
      process.once('SIGINT', cleanup);
      const tick = setInterval(() => {
        const e = env((Date.now() - start) / 1000);
        if (e === null) return cleanup();
        const colors = cfg.channels.map((_, i) => [i, rgb[0] * e, rgb[1] * e, rgb[2] * e]);
        try { socket.send(buildFrame(cfg.id, seq++, colors)); } catch { cleanup(); }
      }, 20);
    });
  } finally {
    await deactivate(cfg.id);
    await restoreLights(snap);  // force the pre-flash color back; bridge restore is unreliable
  }
}

// sRGB (0..1) → CIE xy chromaticity (Philips Wide-RGB D65 gamut), for REST sets.
function rgbToXy([r, g, b]) {
  const gam = (c) => (c > 0.04045 ? Math.pow((c + 0.055) / 1.055, 2.4) : c / 12.92);
  const R = gam(r), G = gam(g), B = gam(b);
  const X = R * 0.664511 + G * 0.154324 + B * 0.162028;
  const Y = R * 0.283881 + G * 0.668433 + B * 0.047685;
  const Z = R * 0.000088 + G * 0.072310 + B * 0.986039;
  const s = X + Y + Z;
  return s === 0 ? { x: 0.3127, y: 0.329 } : { x: +(X / s).toFixed(4), y: +(Y / s).toFixed(4) };
}

// Scoped, low-key desk-light ping over the REST API. Matches lights by name or
// room substring (case-insensitive), snapshots them, RENDERS the grammar
// envelope (a real breath / taps, not a fixed blip), then SNAPS instantly back
// to exactly what was showing. Never opens an entertainment session, so nothing
// else in the house is touched.
async function cmdFlashRest(rgb, peak, segs, patterns) {
  const stamp = '/tmp/hue-flash-rest.last';
  try { if ((Date.now() - fs.statSync(stamp).mtimeMs) / 1000 < 2) return; } catch {}
  fs.writeFileSync(stamp, String(process.pid));

  const pats = patterns.map((p) => String(p).toLowerCase());
  const lights = (await api('GET', '/resource/light')).data || [];
  const rooms = (await api('GET', '/resource/room')).data || [];
  const deviceToRoom = {};
  for (const room of rooms)
    for (const child of (room.children || []))
      if (child.rtype === 'device') deviceToRoom[child.rid] = (room.metadata?.name || '').toLowerCase();

  const ids = lights.filter((l) => {
    const name = (l.metadata?.name || '').toLowerCase();
    const room = deviceToRoom[l.owner?.rid] || '';
    return pats.some((p) => name.includes(p) || room.includes(p));
  }).map((l) => l.id);
  if (!ids.length) return;

  const snap = await snapshotLights(ids);
  const xy = rgbToXy(rgb);
  const brightness = Math.max(1, Math.min(100, Math.round(peak * 100)));

  try {
    // Render the actual grammar envelope (real breath / taps) — drive all scoped
    // lights in lockstep over REST. lit seg = swell up to peak then ease back
    // down over the seg; gap = hold low. Matches the sine envelope the whole-room
    // entertainment path plays, so desk-scoped events feel the same, just softer.
    const lo = 1;  // near-dark trough between pulses (true prior state restored after)
    const setAll = (bri, ms) => Promise.all(ids.map((id) =>
      api('PUT', `/resource/light/${id}`, {
        on: { on: true }, dimming: { brightness: bri }, color: { xy },
        dynamics: { duration: Math.max(0, Math.round(ms)) },
      })));
    const wait = (ms) => new Promise((r) => setTimeout(r, ms));
    for (const [dur, lit] of segs) {
      const ms = dur * 1000;
      if (lit) {
        await setAll(brightness, ms * 0.5); await wait(ms * 0.5);  // swell up
        await setAll(lo, ms * 0.5);          await wait(ms * 0.5);  // ease down
      } else {
        await wait(ms);                                            // gap between taps
      }
    }
  } finally {
    // Snap out instantly (duration 0, no settle) back to the prior state.
    for (const s of snap) {
      try { await api('PUT', `/resource/light/${s.id}`, buildLightRestoreBody(s, 0)); }
      catch { /* best-effort per light */ }
      await new Promise((r) => setTimeout(r, 30));
    }
  }
}

// ─── Daemon ────────────────────────────────────────────────────────────────

async function cmdDaemon(initialAmbient = 'dark', skipActivate = false) {
  const { cfg, streamers } = await ensureConfig();
  console.log(`[daemon] ambient=${initialAmbient}  channels=${cfg.channels.length}  port=${DAEMON_PORT}`);

  if (!skipActivate) {
    await activate(cfg.id);
  } else {
    // Verify config is already active (pre-activated by wrapper script)
    const check = await api('GET', `/resource/entertainment_configuration/${cfg.id}`);
    if (check.data?.[0]?.status !== 'active') {
      console.log('[daemon] config not active despite --no-activate, activating...');
      await activate(cfg.id);
    } else {
      console.log('[daemon] config already active (pre-activated), connecting DTLS...');
    }
  }

  // DTLS connect with retry
  let socket;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      socket = await openSocket();
      break;
    } catch (e) {
      console.error(`[daemon] DTLS attempt ${attempt}/3 failed: ${e.message}`);
      if (attempt === 3) throw e;
      // Re-activate and retry
      console.log('[daemon] re-activating before retry...');
      await activate(cfg.id);
    }
  }
  console.log('[daemon] DTLS connected, streaming @ 50Hz + immediate-on-pulse');

  const state = {
    ambientFn: null,  // set below, once state exists (screen ambient needs it)
    bursts: [],
    highlight: null,  // { targetSet: Set<channelIdx>, color: [r,g,b] } — overrides ambient+bursts on match
    screen: { zones: [], current: {} },  // screen-sync: live color bands + per-channel eased state
    channelNames: streamers.map(s => (s.name || '').toLowerCase()),
    channelRooms: streamers.map(s => (s.room || '').toLowerCase()),
    config: loadConfig(),
    quit: false,
  };
  state.ambientFn = (AMBIENT_FNS[initialAmbient] || dark)(cfg.channels, state);

  // Live-reload config.json
  try {
    fs.watch(CONFIG_FILE, () => {
      try {
        state.config = loadConfig();
        console.log(`[daemon] config reloaded: mode=${state.config.mode} echo=${state.config.echo?.enabled}`);
      } catch {}
    });
  } catch {}

  const startT = Date.now();
  let seq = 0;

  const pushFrame = () => {
    const t = (Date.now() - startT) / 1000;
    const colors = renderFrame(cfg.channels, t, state);
    try { socket.send(buildFrame(cfg.id, seq++, colors)); } catch {}
  };

  const udp = dgram.createSocket('udp4');
  udp.on('message', (buf) => {
    try {
      const msg = JSON.parse(buf.toString());
      handleMessage(msg, state, cfg.channels);
      // Pulse arriving mid-interval: push an extra frame right now so the
      // bulb doesn't wait 0-20ms for the next tick.
      if (msg.type === 'pulse' || msg.type === 'highlight' || msg.type === 'flash') pushFrame();
    } catch (e) { console.error('[daemon] bad message:', e.message); }
  });
  udp.bind(DAEMON_PORT, '127.0.0.1', () => console.log('[daemon] listening on UDP 127.0.0.1:' + DAEMON_PORT));

  const cleanup = async () => {
    clearInterval(tick);
    try { udp.close(); } catch {}
    try { socket.close(); } catch {}
    // Deactivate entertainment config so lights return to normal control
    await deactivate(cfg.id);
    // Brief pause to let bridge release entertainment control
    await new Promise(r => setTimeout(r, 500));
    console.log('\n[daemon] shut down cleanly, lights returned to normal.');
    process.exit(0);
  };
  process.on('SIGINT', cleanup);
  process.on('SIGTERM', cleanup);

  const tick = setInterval(() => {
    if (state.quit) return cleanup();
    pushFrame();
  }, 20);
}

function handleMessage(msg, state, channels) {
  switch (msg.type) {
    case 'ambient':
      if (AMBIENT_FNS[msg.name]) state.ambientFn = AMBIENT_FNS[msg.name](channels, state);
      break;
    case 'screen':
      // External sampler pushes left→right color bands from the primary display.
      if (Array.isArray(msg.zones)) state.screen.zones = msg.zones;
      break;
    case 'flash': {
      // Transient additive flash that auto-returns to whatever was playing
      // (screen-sync, warm, rainbow…). Great for "MAJOR event" dings.
      const color = msg.color || [1, 1, 1];
      const count = Math.max(1, Math.min(10, msg.count || 1));
      const dur = msg.duration || 0.18;
      const gap = msg.gap != null ? msg.gap : 0.12;
      const targets = Array.isArray(msg.target) && msg.target.length ? msg.target : null;
      const targetSet = targets ? resolveTargets(targets, state) : null;
      const now = Date.now() / 1000;
      for (let k = 0; k < count; k++) {
        state.bursts.push({
          pos: [0, 0, 0],
          color,
          startT: now + k * (dur + gap),
          duration: dur,
          radius: 999,
          targetSet,
          uniform: true,  // hit all matched lights equally, ignore spatial falloff
        });
      }
      if (state.bursts.length > 200) state.bursts = state.bursts.slice(-200);
      break;
    }
    case 'pulse': {
      const kc = state.config || {};
      const mode = kc.mode || 'uniform';
      // msg.target overrides config (for CLI trigger commands like dev.sh)
      const explicitTargets = Array.isArray(msg.target) && msg.target.length > 0;
      const echoEnabled = kc.echo?.enabled && !explicitTargets;

      if (echoEnabled) {
        // Echo mode: ripple outward through layers with increasing delay
        for (const layer of (kc.echo?.layers || [])) {
          const targetSet = resolveTargets(layer.targets, state);
          const durMult = layer.duration || 1.0;
          state.bursts.push({
            pos: msg.position || [0, 0, 0],
            color: (msg.color || [1, 1, 1]).map(c => c * (layer.brightness ?? 1)),
            startT: Date.now() / 1000 + (layer.delay || 0) / 1000,
            duration: (msg.duration || 0.35) * durMult,
            radius: msg.radius || 0.6,
            targetSet,
            uniform: mode === 'uniform',
          });
        }
      } else {
        // Normal mode: single burst, targets from msg or config
        const targets = explicitTargets ? msg.target : (kc.targets || null);
        const targetSet = targets ? resolveTargets(targets, state) : null;
        state.bursts.push({
          pos: msg.position || [0, 0, 0],
          color: msg.color || [1, 1, 1],
          startT: Date.now() / 1000,
          duration: msg.duration || 0.35,
          radius: msg.radius || 0.6,
          targetSet,
          uniform: mode === 'uniform',
        });
      }
      if (state.bursts.length > 200) state.bursts = state.bursts.slice(-200);
      break;
    }
    case 'clear':
      state.bursts = [];
      break;
    case 'highlight': {
      // Sticky override — render target channels with a solid color until another
      // highlight or an empty-target highlight replaces it. Used by `huetype pick`.
      if (!Array.isArray(msg.target) || msg.target.length === 0) {
        state.highlight = null;
      } else {
        const patterns = msg.target.map(p => String(p).toLowerCase());
        const targetSet = new Set();
        const N = (state.channelNames || []).length;
        for (let i = 0; i < N; i++) {
          const nameHit = patterns.some(p => state.channelNames[i].includes(p));
          const roomHit = patterns.some(p => (state.channelRooms[i] || '').includes(p));
          if (nameHit || roomHit) targetSet.add(i);
        }
        state.highlight = { targetSet, color: msg.color || [1, 1, 1] };
      }
      break;
    }
    case 'quit':
      state.quit = true;
      break;
  }
}

function renderFrame(channels, t, state) {
  const colors = [];
  const tNow = Date.now() / 1000;
  state.bursts = state.bursts.filter(b => tNow - b.startT < b.duration);

  for (let i = 0; i < channels.length; i++) {
    let [r, g, b] = state.ambientFn(i, t, channels[i]);

    for (const burst of state.bursts) {
      if (burst.targetSet && !burst.targetSet.has(i)) continue;
      const age = tNow - burst.startT;
      if (age < 0) continue; // echo layer not yet started
      const linear = 1 - age / burst.duration;
      if (linear <= 0) continue;
      // Smooth envelope: quick but soft attack, gentle ease-out release
      const timeFade = linear * linear * (3 - 2 * linear); // smoothstep

      let intensity;
      if (burst.uniform) {
        // Uniform mode: all targeted lights get equal brightness
        intensity = timeFade;
      } else {
        // Spatial mode: distance-based falloff from key position
        const p = channels[i].position;
        const dx = p.x - burst.pos[0];
        const dy = p.y - burst.pos[1];
        const dz = p.z - burst.pos[2];
        const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
        intensity = Math.max(0, 1 - dist / burst.radius) * timeFade;
      }
      r = Math.min(1, r + burst.color[0] * intensity);
      g = Math.min(1, g + burst.color[1] * intensity);
      b = Math.min(1, b + burst.color[2] * intensity);
    }

    // Highlight override: solid color on matched channels (for `huetype pick`).
    if (state.highlight && state.highlight.targetSet.has(i)) {
      [r, g, b] = state.highlight.color;
    }

    colors.push([i, r, g, b]);
  }
  return colors;
}

// ─── Trigger: send UDP to running daemon ──────────────────────────────────

function cmdTrigger(args) {
  const [kind, ...rest] = args;
  let msg;
  if (kind === 'ambient') {
    msg = { type: 'ambient', name: rest[0] };
  } else if (kind === 'pulse') {
    const [x, y, z, r = 1, g = 1, b = 1, dur = 0.35, radius = 0.6] = rest.map(parseFloat);
    msg = { type: 'pulse', position: [x, y, z], color: [r, g, b], duration: dur, radius };
  } else if (kind === 'flash') {
    const [r = 1, g = 1, b = 1, count = 2, dur = 0.18] = rest.map(parseFloat);
    msg = { type: 'flash', color: [r, g, b], count, duration: dur };
  } else if (kind === 'clear') {
    msg = { type: 'clear' };
  } else if (kind === 'quit') {
    msg = { type: 'quit' };
  }
  if (!msg) { console.error('bad trigger args'); process.exit(1); }

  const client = dgram.createSocket('udp4');
  client.send(Buffer.from(JSON.stringify(msg)), DAEMON_PORT, '127.0.0.1', (err) => {
    if (err) console.error(err);
    client.close();
  });
}

async function main() {
  const [cmd, ...rest] = process.argv.slice(2);
  const dur = parseFloat(rest[0]) || 15;
  switch (cmd) {
    case 'setup':    return cmdSetup();
    case 'rainbow':  return cmdRun('rainbow', dur);
    case 'matrix':   return cmdRun('matrix', dur);
    case 'stop':     return cmdStop();
    case 'flash':    return cmdFlash(rest[0]);
    case 'daemon': {
      const noActivate = rest.includes('--no-activate');
      const ambient = rest.find(a => a !== '--no-activate') || 'dark';
      return cmdDaemon(ambient, noActivate);
    }
    case 'trigger':  return cmdTrigger(rest);
    default:
      console.log(`commands:
  setup                          create/verify entertainment config
  rainbow|matrix [s]             one-shot animations
  daemon [dark|rainbow|matrix|warm|screen]  long-running: holds DTLS, listens for UDP events (default dark)
  trigger ambient <name>         switch daemon's ambient (rainbow|matrix|dark|warm|screen)
  trigger pulse x y z [r g b dur] fire a spatial burst
  trigger flash [r g b count dur] flash all lights then return to prior state
  trigger quit                   shut down daemon
  stop                           force-deactivate any active stream
  flash [fyi|done|needs|error]   one-shot grammar flash: short session,
                                 play envelope, close — bridge state restored
  `);
  }
}

main().catch(e => { console.error(e); process.exit(1); });
