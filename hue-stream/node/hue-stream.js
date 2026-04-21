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
const POS_FILE = path.join(os.homedir(), '.local/share/hue/positions.json');

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
  }).filter(s => s.lightId);

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

  return { cfg, streamers };
}

async function activate(cfgId) {
  const result = await api('PUT', `/resource/entertainment_configuration/${cfgId}`, { action: 'start' });
  if (result.errors?.length) throw new Error('activate: ' + JSON.stringify(result.errors));
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 150));
    const cur = await api('GET', `/resource/entertainment_configuration/${cfgId}`);
    if (cur.data?.[0]?.status === 'active') return;
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
      timeout: 5000,
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

const AMBIENT_FNS = { rainbow, matrix, dark };

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

async function cmdDaemon(initialAmbient = 'dark') {
  const { cfg, streamers } = await ensureConfig();
  console.log(`[daemon] ambient=${initialAmbient}  channels=${cfg.channels.length}  port=${DAEMON_PORT}`);
  await activate(cfg.id);
  const socket = await openSocket();
  console.log('[daemon] DTLS connected, streaming @ 50Hz + immediate-on-pulse');

  const state = {
    ambientFn: (AMBIENT_FNS[initialAmbient] || dark)(cfg.channels),
    bursts: [],
    channelNames: streamers.map(s => (s.name || '').toLowerCase()),
    channelRooms: streamers.map(s => (s.room || '').toLowerCase()),
    quit: false,
  };

  const startT = Date.now();
  let seq = 0;

  const pushFrame = () => {
    const t = (Date.now() - startT) / 1000;
    const colors = renderFrame(cfg.channels, t, state);
    // DEBUG: if channel 0 is ever non-zero, log it
    const ch0 = colors[0];
    if (ch0 && (ch0[1] > 0.01 || ch0[2] > 0.01 || ch0[3] > 0.01) && !state._ch0Logged) {
      console.log(`[daemon] channel 0 got non-zero: (${ch0[1].toFixed(2)}, ${ch0[2].toFixed(2)}, ${ch0[3].toFixed(2)}) bursts=${state.bursts.length}`);
      state._ch0Logged = true;
      setTimeout(() => state._ch0Logged = false, 500);
    }
    try { socket.send(buildFrame(cfg.id, seq++, colors)); } catch {}
  };

  const udp = dgram.createSocket('udp4');
  udp.on('message', (buf) => {
    try {
      const msg = JSON.parse(buf.toString());
      handleMessage(msg, state, cfg.channels);
      // Pulse arriving mid-interval: push an extra frame right now so the
      // bulb doesn't wait 0-20ms for the next tick.
      if (msg.type === 'pulse') pushFrame();
    } catch (e) { console.error('[daemon] bad message:', e.message); }
  });
  udp.bind(DAEMON_PORT, '127.0.0.1', () => console.log('[daemon] listening on UDP 127.0.0.1:' + DAEMON_PORT));

  const cleanup = async () => {
    clearInterval(tick);
    try { udp.close(); } catch {}
    try { socket.close(); } catch {}
    await deactivate(cfg.id);
    console.log('\n[daemon] shut down cleanly.');
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
      // Target matches against Hue ROOM name (preferred) OR light name.
      // Rooms are the right abstraction — light names can be misleading.
      let targetSet = null;
      if (Array.isArray(msg.target) && msg.target.length > 0) {
        const patterns = msg.target.map(p => String(p).toLowerCase());
        targetSet = new Set();
        const N = (state.channelNames || []).length;
        for (let i = 0; i < N; i++) {
          const nameHit = patterns.some(p => state.channelNames[i].includes(p));
          const roomHit = patterns.some(p => (state.channelRooms[i] || '').includes(p));
          if (nameHit || roomHit) targetSet.add(i);
        }
      }
      state.bursts.push({
        pos: msg.position || [0, 0, 0],
        color: msg.color || [1, 1, 1],
        startT: Date.now() / 1000,
        duration: msg.duration || 0.35,
        radius: msg.radius || 0.6,
        targetSet,
      });
      if (state.bursts.length > 200) state.bursts = state.bursts.slice(-200);
      break;
    }
    case 'clear':
      state.bursts = [];
      break;
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
      const timeFade = 1 - age / burst.duration;
      if (timeFade <= 0) continue;
      const p = channels[i].position;
      const dx = p.x - burst.pos[0];
      const dy = p.y - burst.pos[1];
      const dz = p.z - burst.pos[2];
      const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
      const falloff = Math.max(0, 1 - dist / burst.radius);
      const intensity = falloff * timeFade;
      r = Math.min(1, r + burst.color[0] * intensity);
      g = Math.min(1, g + burst.color[1] * intensity);
      b = Math.min(1, b + burst.color[2] * intensity);
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
    case 'daemon':   return cmdDaemon(rest[0] || 'dark');
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
