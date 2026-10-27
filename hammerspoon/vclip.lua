-- vclip.lua : big floating CLIP button for the vertical canvas backtrack (EJ 2026-10-26:
-- "a big ass floating button I can put anywhere on my two screens ... or if the window is
-- focused, an enter triggers it"). Click it, or focus it and press Enter -> ~/.dotfiles/bin/vclip
-- (Aitum Vertical save_backtrack over obs-websocket). Floats above everything on every space,
-- drag it by its title bar to either screen; the spot is remembered. Shown while OBS runs.
-- Console: vclip.show() / vclip.hide()
local M = {}
local VCLIP = os.getenv("HOME") .. "/.dotfiles/bin/vclip"
local VCFG = os.getenv("HOME") .. "/Library/Application Support/obs-studio/plugin_config/vertical-canvas/config.json"
local KEY = "vclip.frame"
local view, busy = nil, false

local function seconds()
  local ok, d = pcall(hs.json.read, VCFG)
  if not ok or not d then return 30 end
  local c = d
  if type(d.canvas) == "table" and d.canvas[1] then c = d.canvas[1] end
  return c.backtrack_seconds or 30
end

local HTML = [[
<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;height:100%;background:#000;font-family:"IBM Plex Mono",ui-monospace,Menlo,monospace;
    -webkit-user-select:none;cursor:default;}
  button{all:unset;box-sizing:border-box;width:100%;height:100%;display:flex;flex-direction:column;
    align-items:center;justify-content:center;gap:8px;background:#000;color:#fff;}
  button:hover{background:#111;}
  button:focus-visible{outline:none;box-shadow:inset 0 0 0 2px rgba(255,255,255,.35);}
  /* type scales with the window (it's resizable): whichever of width/height is tighter wins */
  .big{font-family:"Archivo Black",Impact,sans-serif;font-size:min(42vh,21vw);letter-spacing:.06em;line-height:1;}
  .sub{font-size:min(8vh,4.4vw);letter-spacing:.28em;text-transform:uppercase;color:rgba(255,255,255,.5);
    max-width:92%;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;text-align:center;}
  body.busy .big{opacity:.4;}
  body.ok button{background:#fff;color:#000;} body.ok .sub{color:rgba(0,0,0,.6);}
</style></head><body>
<button id="b" autofocus><span class="big" id="big">CLIP</span><span class="sub" id="sub">vertical · last __S__s</span></button>
<script>
  const IDLE = "vertical · last __S__s";
  let busy = false;
  function fire(){ if(busy) return; busy = true; document.body.className = "busy";
    document.getElementById("sub").textContent = "saving…";
    webkit.messageHandlers.vclip.postMessage("clip"); }
  function done(kind, msg){
    document.body.className = kind === "OK" ? "ok" : "";
    document.getElementById("big").textContent = kind === "OK" ? "SAVED" : (kind === "WAIT" ? "WAIT" : "ERROR");
    document.getElementById("sub").textContent = msg;
    setTimeout(() => { busy = false; document.body.className = "";
      document.getElementById("big").textContent = "CLIP";
      document.getElementById("sub").textContent = IDLE; }, 2600);
  }
  document.getElementById("b").addEventListener("click", fire);
  addEventListener("keydown", e => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); fire(); } });
</script></body></html>]]

local function run(wv)
  if busy then return end
  busy = true
  hs.task.new(VCLIP, function(_, out, err)
    busy = false
    local line = ((out or "") .. ""):gsub("%s+$", "")
    local kind, msg = line:match("^(%u+)%s*(.*)$")
    if not kind then kind, msg = "ERR", (err or "no output"):sub(1, 60) end
    msg = msg:gsub("\\", "\\\\"):gsub("'", "\\'")
    if wv then wv:evaluateJavaScript(string.format("done('%s','%s')", kind, msg)) end
  end):start()
end

local function build()
  local f = hs.settings.get(KEY)
  local frame
  if f then
    frame = hs.geometry.rect(f.x, f.y, f.w, f.h)
  else
    local s = (hs.screen.find("DELL") or hs.screen.primaryScreen()):frame()
    frame = hs.geometry.rect(s.x + s.w - 300, s.y + s.h - 220, 260, 150)
  end
  local uc = hs.webview.usercontent.new("vclip")
  uc:setCallback(function() run(view) end)
  view = hs.webview.new(frame, { developerExtrasEnabled = false }, uc)
    :windowStyle({ "titled", "closable", "resizable", "utility", "HUD" })
    :windowTitle("CLIP")
    :level(hs.drawing.windowLevels.floating)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces + hs.drawing.windowBehaviors.stationary)
    :allowTextEntry(true)
    :deleteOnClose(false)
    :closeOnEscape(false)
    :html((HTML:gsub("__S__", tostring(seconds()))))
  view:windowCallback(function(action, _, fr)
    if action == "frameChange" and fr then hs.settings.set(KEY, { x = fr.x, y = fr.y, w = fr.w, h = fr.h }) end
  end)
end

function M.show()
  if not view then build() end
  view:html((HTML:gsub("__S__", tostring(seconds()))))   -- picks up a changed backtrack length
  view:show()
end

function M.hide()
  if view then view:hide() end
end

-- reopen from the menu bar any time (EJ: "easy to reopen"): click = bring the button back
-- (and to the front of the floating layer); the X on the button only hides it
M.menu = hs.menubar.new(true, "vclip")
if M.menu then
  M.menu:setTitle("CLIP")
  M.menu:setTooltip("Show the vertical CLIP button")
  M.menu:setClickCallback(function() M.show() end)
end

-- visible while OBS runs (the clip only exists in OBS's buffer); no focus is taken on show
M.watcher = hs.application.watcher.new(function(name, ev)
  if name ~= "OBS" and name ~= "OBS Studio" then return end
  if ev == hs.application.watcher.launched then hs.timer.doAfter(3, M.show) end
  if ev == hs.application.watcher.terminated then M.hide() end
end):start()
if hs.application.get("com.obsproject.obs-studio") then M.show() end

_G.vclip = M
return M
