const { Agent, setGlobalDispatcher } = require("undici");
setGlobalDispatcher(new Agent({ connect: { rejectUnauthorized: false } }));
async function go() {
  const BRIDGE = process.env.HUE_BRIDGE_IP;
  const KEY = process.env.HUE_APP_KEY;
  const api = async (p) => {
    const r = await fetch(`https://${BRIDGE}/clip/v2${p}`, { headers: { "hue-application-key": KEY } });
    return (await r.json());
  };
  const ent = (await api("/resource/entertainment")).data.filter(e => e.renderer);
  const lights = (await api("/resource/light")).data;
  const rooms = (await api("/resource/room")).data;
  const deviceToRoom = {};
  for (const room of rooms) {
    for (const child of (room.children || [])) {
      if (child.rtype === "device") deviceToRoom[child.rid] = room.metadata.name;
    }
  }
  const streamers = ent.map(e => {
    const light = lights.find(l => l.owner && l.owner.rid === e.owner.rid);
    return {
      name: (light && light.metadata ? light.metadata.name : "?").toLowerCase(),
      room: (deviceToRoom[e.owner.rid] || "").toLowerCase(),
    };
  }).filter(s => s.name !== "?");
  console.log("Channel names/rooms the daemon sees:");
  streamers.forEach((s, i) => console.log("  ch" + i, "name=" + JSON.stringify(s.name), "room=" + JSON.stringify(s.room)));
  const targets = ["desk", "dj", "color", "lamp"];
  console.log("\nTarget patterns from Hammerspoon:", targets);
  streamers.forEach((s, i) => {
    const nameHit = targets.some(p => s.name.includes(p));
    const roomHit = targets.some(p => s.room.includes(p));
    console.log("  ch" + i, s.name, "-> nameHit=" + nameHit, "roomHit=" + roomHit);
  });
}
go();
