-- hue-key: every keypress → spatial color burst in the house lights
-- Sends UDP JSON to the hue-stream daemon on localhost:9999.

require("hs.ipc")  -- enables `hs -c "..."` CLI for debugging

-- ── Config ──────────────────────────────────────────────────────────────
local STREAK_GAP = 0.8       -- seconds of silence that resets streak
local STREAK_SPAN = 2400     -- keys to traverse hue journey start → end
local PULSE_DURATION = 0.65  -- per-key fade time (longer release)
local PULSE_RADIUS = 0.5     -- spatial falloff — smaller = less light-bleed into adjacent rooms
local CONFIG_FILE = os.getenv("HOME") .. "/.config/hue-key/config.json"

-- HCL journey: Lab/LCH is perceptually uniform, so equal streak steps feel equal.
-- Fixed L (luminance) and C (chroma) keep saturation/brightness constant;
-- only hue rotates, avoiding the RGB "muddy midpoint" problem.
local HCL_L = 28             -- luminance (0-100). Lower = darker / more saturated feel
local HCL_C = 95             -- chroma (0-~100). Higher = more vivid (clamps to gamut edge)
local HCL_H_START = 15       -- starting hue in degrees (deep red)
local HCL_H_END = 285        -- ending hue in degrees (deep indigo)

local udp = hs.socket.udp.new()

-- ── Physical keyboard layout ────────────────────────────────────────────
local rows = {
  { 53, 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 51 },
  { 50, 18, 19, 20, 21, 23, 22, 26, 28, 25, 29, 27, 24 },
  { 48, 12, 13, 14, 15, 17, 16, 32, 34, 31, 35, 33, 30, 42 },
  { 57, 0, 1, 2, 3, 5, 4, 38, 40, 37, 41, 39, 36 },
  { 56, 6, 7, 8, 9, 11, 45, 46, 43, 47, 44, 60 },
  { 59, 58, 55, 49, 54, 61, 63, 123, 125, 126, 124 },
}

local keyPos = {}
for r = 1, #rows do
  local row = rows[r]
  local y = 1 - (r - 1) * (2 / (#rows - 1))
  for c = 1, #row do
    local x = (#row > 1) and ((c - 1) / (#row - 1) * 2 - 1) or 0
    keyPos[row[c]] = { x, y }
  end
end

-- ── HCL (Lab polar) → sRGB ──────────────────────────────────────────────
-- Perceptually uniform color space — equal hue steps look equal to the eye.
local function hcl2rgb(h_deg, c, l)
  local hrad = h_deg * math.pi / 180
  local a = c * math.cos(hrad)
  local b_star = c * math.sin(hrad)
  -- LCH → Lab (already done via a, b_star above) → XYZ (D65 illuminant)
  local function f_inv(t)
    return t > 6/29 and t^3 or 3 * (6/29)^2 * (t - 4/29)
  end
  local fy = (l + 16) / 116
  local X = 0.95047 * f_inv(fy + a / 500)
  local Y = f_inv(fy)
  local Z = 1.08883 * f_inv(fy - b_star / 200)
  -- XYZ → linear sRGB
  local r =  3.2406 * X - 1.5372 * Y - 0.4986 * Z
  local g = -0.9689 * X + 1.8758 * Y + 0.0415 * Z
  local bl = 0.0557 * X - 0.2040 * Y + 1.0570 * Z
  -- Gamma correct (linear → sRGB) and clamp
  local function gamma(v)
    if v <= 0 then return 0 end
    if v <= 0.0031308 then return 12.92 * v end
    return 1.055 * v^(1/2.4) - 0.055
  end
  local function clamp(v) return math.max(0, math.min(1, v)) end
  return clamp(gamma(r)), clamp(gamma(g)), clamp(gamma(bl))
end

-- ── Config watcher (informational — daemon owns routing/echo logic) ────
-- Edit ~/.config/hue-key/config.json to change mode, targets, and echo layers.
if hueConfigWatcher then hueConfigWatcher:stop() end
hueConfigWatcher = hs.pathwatcher.new(CONFIG_FILE, function()
  local f = io.open(CONFIG_FILE, "r")
  if not f then return end
  local ok, cfg = pcall(hs.json.decode, f:read("*a"))
  f:close()
  if ok and cfg then
    local mode = cfg.mode or "uniform"
    local echo = cfg.echo and cfg.echo.enabled
    hs.alert.show("hue-key: " .. mode .. (echo and " + echo" or ""), 1.5)
  end
end):start()

local function sendPulse(x, y, r, g, b, dur, radius)
  local msg = string.format(
    '{"type":"pulse","position":[%.3f,%.3f,0],"color":[%.3f,%.3f,%.3f],"duration":%.2f,"radius":%.2f}',
    x, y, r, g, b, dur, radius
  )
  udp:send(msg, "127.0.0.1", 9999)
end

-- ── Streak state ────────────────────────────────────────────────────────
local lastKeyTime = 0
local streak = 0

-- ── Event tap ───────────────────────────────────────────────────────────
-- Explicitly kill any previous tap from an earlier reload before making a new one.
if hueKeyTap then
  pcall(function() hueKeyTap:stop() end)
  hueKeyTap = nil
end
hueKeyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local kc = event:getKeyCode()
  local pos = keyPos[kc]
  if not pos then return false end

  local now = hs.timer.secondsSinceEpoch()
  if now - lastKeyTime < STREAK_GAP then
    streak = streak + 1
  else
    streak = 1
  end
  lastKeyTime = now

  -- Streak progresses through perceptually-uniform hue space (HCL).
  local frac = math.min(streak - 1, STREAK_SPAN) / STREAK_SPAN
  local h = HCL_H_START + frac * (HCL_H_END - HCL_H_START)
  local r, g, b = hcl2rgb(h, HCL_C, HCL_L)
  sendPulse(pos[1], pos[2], r, g, b, PULSE_DURATION, PULSE_RADIUS)
  return false
end)
hueKeyTap:start()

local count = 0
for _ in pairs(keyPos) do count = count + 1 end
hs.alert.show("hue-key loaded: " .. count .. " keys live", 3)

-- ── Window management ───────────────────────────────────────────────────────
-- Moved OUT of Hammerspoon (2026-06-27). The old hs.eventtap window-mode was
-- silently starved by macOS Secure Event Input (Safari password fields, etc.),
-- so Ctrl+Space went dead with no error and the watchdog couldn't see it.
-- Window snapping now lives in two secure-input-immune layers:
--   • Rectangle Pro  — does the actual snap   (Carbon RegisterEventHotKey)
--   • Karabiner      — Ctrl+Space leader → fires Rectangle's ⌃⌥ h/j/k/l/m, o/u
-- See ~/.dotfiles/hammerspoon/RETROSPECTIVE-window-mode.md for the full story.

-- ── Robustness: keep the hue-key eventtap alive ─────────────────────────────
-- macOS silently disables eventtaps after sleep/wake (hammerspoon #1502/#1859).
-- Re-arm on wake + a periodic health check. Only hueKeyTap uses a tap now —
-- window-mode no longer does, so it can never be starved by secure input.
local function rearmTaps()
  if hueKeyTap then pcall(function() hueKeyTap:stop(); hueKeyTap:start() end) end
  if modLogTap then pcall(function() modLogTap:stop(); modLogTap:start() end) end
end
if caffeineWatcher then caffeineWatcher:stop() end
caffeineWatcher = hs.caffeinate.watcher.new(function(ev)
  local W = hs.caffeinate.watcher
  if ev == W.systemDidWake or ev == W.screensDidWake or ev == W.sessionDidBecomeActive then
    rearmTaps()
  end
end):start()
if tapHealthTimer then tapHealthTimer:stop() end
tapHealthTimer = hs.timer.doEvery(30, function()
  if hueKeyTap and not hueKeyTap:isEnabled() then pcall(function() hueKeyTap:start() end) end
  if modLogTap and not modLogTap:isEnabled() then pcall(function() modLogTap:start() end) end
end)

-- ── Modifier transition logging (stuck-⌘ hunt, 2026-07-12) ──────────────────
-- Logs every modifier state CHANGE (post-Karabiner, what apps actually see) to
-- ~/.local/share/usage-logs/modifiers/YYYY-MM-DD.jsonl with ms timestamps and
-- the raw keycode that caused it (55=left⌘ 54=right⌘ 58=l⌥ 61=r⌥ 56=l⇧ 60=r⇧
-- 59=l⌃ 62=r⌃). A "cmd" entry with no following "" entry = stuck at flag level.
-- Remove this section once the Karabiner 16.1.0 stuck-modifier bug is resolved.
local MODLOG_DIR = os.getenv("HOME") .. "/.local/share/usage-logs/modifiers/"
local prevMods = "?"
if modLogTap then modLogTap:stop() end
modLogTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(e)
  local f = e:getFlags()
  local names = {}
  for _, k in ipairs({ "cmd", "alt", "ctrl", "shift", "fn" }) do
    if f[k] then names[#names + 1] = k end
  end
  local cur = table.concat(names, " ")
  if cur ~= prevMods then
    prevMods = cur
    local now = hs.timer.secondsSinceEpoch()
    local out = io.open(MODLOG_DIR .. os.date("%Y-%m-%d") .. ".jsonl", "a")
    if out then
      out:write(string.format('{"ts":"%s.%03dZ","mods":%q,"keycode":%d}\n',
        os.date("!%Y-%m-%dT%H:%M:%S", math.floor(now)), math.floor((now % 1) * 1000),
        cur, e:getKeyCode()))
      out:close()
    end
  end
  return false
end)
modLogTap:start()

-- ── Auto-reload config on save ──────────────────────────────────────────────
-- init.lua is symlinked from the dotfiles; watch that dir and reload on save.
if configReloader then configReloader:stop() end
configReloader = hs.pathwatcher.new(os.getenv("HOME") .. "/.dotfiles/hammerspoon/", function(paths)
  for _, p in ipairs(paths) do
    if p:sub(-4) == ".lua" then
      hs.timer.doAfter(0.25, hs.reload)  -- small debounce so the save fully lands
      return
    end
  end
end):start()

-- ── Window arrangement logging ───────────────────────────────────────────────
-- Snapshots all standard windows every 5 min (+ after every ⌥Space snap) to
-- ~/.local/share/usage-logs/windows/YYYY-MM-DD.jsonl — same convention as the
-- shell/nvim/tmux usage logs. Positions are screen FRACTIONS (0-1) so they map
-- directly onto SNAP_UNITS. Purpose: mine a week of real arranging behavior to
-- design layout presets from actual usage, not guesses.
local WINLOG_DIR = os.getenv("HOME") .. "/.local/share/usage-logs/windows/"
local function logWindowSnapshot(trigger)
  local focused = hs.window.focusedWindow()
  local wins = {}
  for _, w in ipairs(hs.window.orderedWindows()) do
    local app = w:application()
    if w:isStandard() and app then
      local f, sf = w:frame(), w:screen():frame()
      wins[#wins + 1] = string.format(
        '{"app":%q,"x":%.3f,"y":%.3f,"w":%.3f,"h":%.3f,"screen":%q,"focused":%s}',
        app:name() or "?", (f.x - sf.x) / sf.w, (f.y - sf.y) / sf.h,
        f.w / sf.w, f.h / sf.h, w:screen():name() or "?", tostring(w == focused))
    end
  end
  local out = io.open(WINLOG_DIR .. os.date("%Y-%m-%d") .. ".jsonl", "a")
  if out then
    out:write(string.format('{"ts":"%s","trigger":%q,"windows":[%s]}\n',
      os.date("!%Y-%m-%dT%H:%M:%SZ"), trigger, table.concat(wins, ",")))
    out:close()
  end
end
if winlogTimer then winlogTimer:stop() end
winlogTimer = hs.timer.doEvery(300, function() pcall(logWindowSnapshot, "periodic") end)

-- ── Window snapping (called by the Karabiner ⌥Space leader via `hs -c`) ──────
-- Karabiner captures ⌥Space + direction and shells out to:
--     /usr/local/bin/hs -c "windowSnap('top')"
-- Snaps the focused window to a half/full of its CURRENT display. If the window
-- is ALREADY sitting at that exact rect, it's thrown to the same slot on the
-- NEXT display (cycles) — so pressing top→top→top walks it across your screens.
-- Uses the Accessibility API (window moves), NOT an eventtap, so macOS Secure
-- Event Input can't starve it — that only ever affected key capture (Karabiner's job).
local SNAP_UNITS = {
  left   = { x = 0,   y = 0,   w = 0.5, h = 1   },
  right  = { x = 0.5, y = 0,   w = 0.5, h = 1   },
  top    = { x = 0,   y = 0,   w = 1,   h = 0.5 },
  bottom = { x = 0,   y = 0.5, w = 1,   h = 0.5 },
  full   = { x = 0,   y = 0,   w = 1,   h = 1   },
  -- Shift layer: quarters
  topLeft     = { x = 0,   y = 0,   w = 0.5, h = 0.5 },
  bottomLeft  = { x = 0,   y = 0.5, w = 0.5, h = 0.5 },
  topRight    = { x = 0.5, y = 0,   w = 0.5, h = 0.5 },
  bottomRight = { x = 0.5, y = 0.5, w = 0.5, h = 0.5 },
}

-- ⇧Space: centered float at 1/φ of the screen; again = 1/φ² (golden all the way down)
local PHI = (1 + math.sqrt(5)) / 2
for name, s in pairs({ golden = 1 / PHI, goldenSmall = 1 / (PHI * PHI) }) do
  SNAP_UNITS[name] = { x = (1 - s) / 2, y = (1 - s) / 2, w = s, h = s }
end

-- Shift+direction = quarter on that side; pressing again toggles to the other
-- quarter on the same side (⇧H: top-left ⇄ bottom-left, ⇧K: top-left ⇄ top-right).
local CYCLES = {
  leftQuarters   = { "topLeft", "bottomLeft" },
  rightQuarters  = { "topRight", "bottomRight" },
  topQuarters    = { "topLeft", "topRight" },
  bottomQuarters = { "bottomLeft", "bottomRight" },
  goldenCenter   = { "golden", "goldenSmall" },
}

local function snapRectFor(screen, u)
  local f = screen:frame()   -- usable area: excludes menu bar + dock
  return hs.geometry.rect(f.x + u.x * f.w, f.y + u.y * f.h, u.w * f.w, u.h * f.h)
end

local function snapSameRect(a, b)
  local tol = 12  -- px slop so near-misses still count as "already there"
  return math.abs(a.x - b.x) < tol and math.abs(a.y - b.y) < tol
     and math.abs(a.w - b.w) < tol and math.abs(a.h - b.h) < tol
end

local lastSnap = nil  -- single-depth undo: frame before the most recent snap

local function cyclePosition(win, screen, cycle)
  for i, name in ipairs(cycle) do
    if snapSameRect(win:frame(), snapRectFor(screen, SNAP_UNITS[name])) then return i end
  end
end

function windowSnap(dir)  -- global on purpose: reachable via `hs -c`
  local cycle = CYCLES[dir]
  local u = SNAP_UNITS[dir]
  if not cycle and not u then return end
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen()
  local target
  if cycle then
    local i = cyclePosition(win, screen, cycle)
    local nextName = i and cycle[i % #cycle + 1] or cycle[1]
    target = snapRectFor(screen, SNAP_UNITS[nextName])
  else
    target = snapRectFor(screen, u)
    if snapSameRect(win:frame(), target) then
      local nxt = screen:next()                     -- cycles; == screen if only one display
      if nxt and nxt:id() ~= screen:id() then
        target = snapRectFor(nxt, u)                -- escalate: same slot, next display
      end
    end
  end
  lastSnap = { id = win:id(), frame = win:frame() }
  win:setFrame(target, 0)                           -- 0 = no animation, instant snap
  hs.timer.doAfter(0.3, function() pcall(logWindowSnapshot, "snap") end)
end

function windowSnapUndo()  -- global: reachable via `hs -c`; ⌥Space u
  local win = hs.window.focusedWindow()
  if win and lastSnap and lastSnap.id == win:id() then
    win:setFrame(lastSnap.frame, 0)
    lastSnap = nil
  end
end

-- ── Autoplace: newborn windows snap to their data-proven home slot ───────────
-- Added 2026-07-15. Mined from a week of window logs (~/.local/share/usage-logs/
-- windows/): a few apps get manually snapped to the same slot nearly every time
-- a window appears — Safari→left-half was the single most common manual snap.
-- This catches NEWLY CREATED windows of whitelisted apps and snaps them there.
--
-- What it will NEVER do: move an existing window, touch float-class apps
-- (Messages, Discord, Things, 1Password, Fantastical — deliberately absent
-- from the table), or move a window already sitting at its home slot (so
-- macOS frame-restoration wins when it's already right).
--
-- ★★ TO DISABLE (if you forgot this exists: yes, Claude added it 2026-07-15) ★★
--   1. Instant, survives reloads:   touch ~/.config/autoplace-disabled
--      (re-enable:                  rm ~/.config/autoplace-disabled)
--   2. This session only:           /usr/local/bin/hs -c "autoplaceFilter:pause()"
--   3. Forever: delete this whole section (down to the next ── rule).
--
-- UNDO a bad placement: ⌥Space u — autoplace sets lastSnap like a manual snap.
-- AUDIT: each placement logs trigger:"autoplace" to the windows JSONL and
-- flashes a 1s alert. To grade it later: autoplace entries followed by a
-- hand-move within ~1 min were wrong guesses → prune that app from the table.
local AUTOPLACE_DISABLE_FILE = os.getenv("HOME") .. "/.config/autoplace-disabled"
local AUTOPLACE_MIN_W, AUTOPLACE_MIN_H = 500, 300 -- px; skips dialog/panel-sized windows

local AUTOPLACE_HOMES = {
  -- app              screen (name substring)  slot (SNAP_UNITS)  evidence, Jul 2026 logs
  ["Safari"]        = { screen = "Retina", slot = "left",  label = "left-half" },      -- #1 manual snap
  ["Mail"]          = { screen = "Retina", slot = "right", label = "right-half" },     -- 93% of observations
  ["Google Chrome"] = { screen = "DELL",   slot = "top",   label = "Dell top-half" },  -- 60% born there already
  ["Spotify"]       = { screen = "DELL",   slot = "top",   label = "Dell top-half" },  -- 100% of observations
}

local function autoplaceScreen(pattern)
  for _, s in ipairs(hs.screen.allScreens()) do
    if (s:name() or ""):find(pattern, 1, true) then return s end
  end
end

local function autoplace(win, appName)
  local home = AUTOPLACE_HOMES[appName]
  if not home then return end
  if hs.fs.attributes(AUTOPLACE_DISABLE_FILE) then return end
  if not win:isStandard() then return end
  -- Mail compose windows are new windows too, but they belong floating
  if appName == "Mail" and (win:title() or ""):find("New Message") then return end
  local f = win:frame()
  if f.w < AUTOPLACE_MIN_W or f.h < AUTOPLACE_MIN_H then return end
  local screen = autoplaceScreen(home.screen)
  if not screen then return end -- target display unplugged → do nothing
  local target = snapRectFor(screen, SNAP_UNITS[home.slot])
  if snapSameRect(f, target) then return end -- already home
  lastSnap = { id = win:id(), frame = f } -- ⌥Space u restores
  win:setFrame(target, 0)
  hs.alert.show("⌂ " .. appName .. " → " .. home.label .. "   (⌥Space u undoes)", 1)
  hs.timer.doAfter(0.3, function() pcall(logWindowSnapshot, "autoplace") end)
end

if autoplaceFilter then autoplaceFilter:unsubscribeAll() end
autoplaceFilter = hs.window.filter.new({ "Safari", "Mail", "Google Chrome", "Spotify" })
autoplaceFilter:subscribe(hs.window.filter.windowCreated, function(win, appName)
  -- brief delay so the app finishes its own frame-restore before we judge
  hs.timer.doAfter(0.25, function() pcall(autoplace, win, appName) end)
end)

hs.alert.show("hammerspoon loaded · window snap (⌥Space) + cross-display + autoplace", 2)
