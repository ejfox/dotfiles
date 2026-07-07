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

const BRIDGE = process.env.HUE_BRIDGE_IP;
const KEY = process.env.HUE_APP_KEY;
const CLIENT_KEY = process.env.HUE_CLIENT_KEY;
const CONFIG_NAME = 'ejfox-stream';
// Comma-separated room names to exclude from the Entertainment group.
// Case-insensitive. Lights in these rooms stay on regular Hue API control
// instead of being blanked by the daemon's ambient.
const EXCLUDE_ROOMS = (process.env.HUE_STREAM_EXCLUDE_ROOMS || '')
  .split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
const POS_FILE = path.join(os.homedir(), '.local/share/hue/positions.json');
const CONFIG_FILE = path.join(os.homedir(), '.config/hue-key/config.json');

if (!BRIDGE || !KEY || !CLIENT_KEY) {
  console.error('error: HUE_BRIDGE_IP, HUE_APP_KEY, HUE_CLIENT_KEY must be set (see ~/.env)');
  process.exit(1);
}

async function api(method, pathStr, body) {
  const res = await fetch(`https://${BRIDGE}/clip/v2${pathStr}`, {
    method,
    headers: { 'hue-application-key': KEY, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  try { return JSON.parse(text); } catch { return text; }
}

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

const AMBIENT_FNS = { rainbow, matrix, dark, warm };

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
    ambientFn: (AMBIENT_FNS[initialAmbient] || dark)(cfg.channels),
    bursts: [],
    highlight: null,  // { targetSet: Set<channelIdx>, color: [r,g,b] } — overrides ambient+bursts on match
    channelNames: streamers.map(s => (s.name || '').toLowerCase()),
    channelRooms: streamers.map(s => (s.room || '').toLowerCase()),
    config: loadConfig(),
    quit: false,
  };

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
      if (msg.type === 'pulse' || msg.type === 'highlight') pushFrame();
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
      if (AMBIENT_FNS[msg.name]) state.ambientFn = AMBIENT_FNS[msg.name](channels);
      break;
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
  daemon [dark|rainbow|matrix]   long-running: holds DTLS, listens for UDP events (default dark)
  trigger ambient <name>         switch daemon's ambient animation
  trigger pulse x y z [r g b dur] fire a spatial burst
  trigger quit                   shut down daemon
  stop                           force-deactivate any active stream
  `);
  }
}

main().catch(e => { console.error(e); process.exit(1); });
