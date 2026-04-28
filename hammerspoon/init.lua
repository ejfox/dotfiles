-- hue-key: every keypress → spatial color burst in the house lights
-- Sends UDP JSON to the hue-stream daemon on localhost:9999.
--
-- Live-reloadable config files in ~/.config/hue-key/ :
--   targets         — comma-separated room/light substrings to target
--   palette         — palette index (1..N) shift-click cycles this
--   wpm-brightness  — touch to enable WPM-modulated brightness (0-180 WPM → dim-full)

require("hs.ipc")  -- enables `hs -c "..."` CLI

-- ── Config ──────────────────────────────────────────────────────────────
local STREAK_GAP = 0.8
local STREAK_SPAN = 2400
local PULSE_DURATION = 0.4
local PULSE_RADIUS = 2.0

local CONFIG_DIR = os.getenv("HOME") .. "/.config/hue-key/"
local TARGETS_FILE = CONFIG_DIR .. "targets"
local PALETTE_FILE = CONFIG_DIR .. "palette"
local WPM_FLAG_FILE = CONFIG_DIR .. "wpm-brightness"
local ENABLED_FILE = CONFIG_DIR .. "enabled"  -- "1" (default) or "0"; written by huetype CLI
local MODE_FILE = CONFIG_DIR .. "mode"        -- "dramatic" (default) or "subtle"

local HCL_L = 42
local HCL_C = 95

-- In "subtle" mode, burst colors get multiplied by this factor so they sit
-- as ~10% bumps on top of the daemon's warm-white baseline rather than
-- full-saturation strobes. Tweak to taste.
local SUBTLE_MULT = 0.18

-- Named palettes — streak traverses h_start → h_end perceptually.
-- Shift-click the sketchybar item to cycle.
local palettes = {
  { name = "vulpes", h_start = 335, h_end = 185 }, -- pink → teal via purples/blues
  { name = "fire",   h_start = 15,  h_end = 55  }, -- red → amber
  { name = "rainbow", h_start = 0,  h_end = 300 }, -- red → violet
  { name = "ocean",  h_start = 180, h_end = 250 }, -- cyan → deep blue
  { name = "bloom",  h_start = 320, h_end = 30  }, -- magenta → gold via reds
}

local WPM_WINDOW = 5
local WPM_MAX = 180
local WPM_MIN_BRIGHT = 0.35

-- Keycodes that should NOT count toward streak / WPM (modifiers, navigation,
-- function keys, escape). Everything still pulses — this only affects metrics.
local NON_TYPING_KEYS = {
  [53]=true,                                     -- escape
  [51]=true,                                     -- delete/backspace (editing, not throughput)
  [54]=true, [55]=true,                          -- right cmd, left cmd
  [56]=true, [60]=true,                          -- left shift, right shift
  [57]=true,                                     -- caps lock
  [58]=true, [61]=true,                          -- left option, right option
  [59]=true, [62]=true,                          -- left control, right control
  [63]=true,                                     -- fn
  [123]=true, [124]=true, [125]=true, [126]=true,-- arrows
  [96]=true, [97]=true, [98]=true, [100]=true,   -- F-keys
  [101]=true, [103]=true, [109]=true, [111]=true,
  [118]=true, [120]=true, [122]=true,
}

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
local function hcl2rgb(h_deg, c, l)
  local hrad = h_deg * math.pi / 180
  local a = c * math.cos(hrad)
  local b_star = c * math.sin(hrad)
  local function f_inv(t)
    return t > 6/29 and t^3 or 3 * (6/29)^2 * (t - 4/29)
  end
  local fy = (l + 16) / 116
  local X = 0.95047 * f_inv(fy + a / 500)
  local Y = f_inv(fy)
  local Z = 1.08883 * f_inv(fy - b_star / 200)
  local r =  3.2406 * X - 1.5372 * Y - 0.4986 * Z
  local g = -0.9689 * X + 1.8758 * Y + 0.0415 * Z
  local bl = 0.0557 * X - 0.2040 * Y + 1.0570 * Z
  local function gamma(v)
    if v <= 0 then return 0 end
    if v <= 0.0031308 then return 12.92 * v end
    return 1.055 * v^(1/2.4) - 0.055
  end
  local function clamp(v) return math.max(0, math.min(1, v)) end
  return clamp(gamma(r)), clamp(gamma(g)), clamp(gamma(bl))
end

-- ── Config loaders (all file-watched, live reload) ──────────────────────
hueTargetJson = ''
huePaletteIdx = 1
hueMode = nil  -- set on first hueLoadMode() call

function hueLoadTargets()
  local f = io.open(TARGETS_FILE, "r")
  if not f then hueTargetJson = ''; return end
  local content = f:read("*a") or ""
  f:close()
  local parts = {}
  for p in string.gmatch(content, "[^,%s]+") do
    parts[#parts + 1] = '"' .. p .. '"'
  end
  hueTargetJson = #parts > 0 and (',"target":[' .. table.concat(parts, ',') .. ']') or ''
end

function hueLoadPalette()
  local f = io.open(PALETTE_FILE, "r")
  local n = 1
  if f then
    n = tonumber((f:read("*a") or "1"):match("%d+")) or 1
    f:close()
  end
  huePaletteIdx = math.max(1, math.min(#palettes, n))
  hs.alert.show("palette: " .. palettes[huePaletteIdx].name, 1.2)
end

function hueWpmEnabled()
  local f = io.open(WPM_FLAG_FILE, "r")
  if not f then return false end
  f:close()
  return true
end

function hueLoadMode()
  local f = io.open(MODE_FILE, "r")
  local new = "dramatic"
  if f then
    local raw = (f:read("*a") or ""):match("%S+") or ""
    f:close()
    if raw == "subtle" then new = "subtle" end
  end
  return new
end

-- ── UDP pulse ───────────────────────────────────────────────────────────
-- udp is module-global (no `local`) so hueReloadConfig can push ambient
-- messages to the daemon on mode change.
udp = hs.socket.udp.new()

function hueApplyMode()
  local ambient = (hueMode == "subtle") and "warm" or "dark"
  udp:send('{"type":"ambient","name":"' .. ambient .. '"}', "127.0.0.1", 9999)
end

function hueReloadConfig()
  hueLoadTargets()
  hueLoadPalette()
  local prev = hueMode
  hueMode = hueLoadMode()
  if hueMode ~= prev then
    hueApplyMode()
    if prev ~= nil then hs.alert.show("huetype: " .. hueMode, 1.0) end
  end
end
hueReloadConfig()

if hueConfigWatcher then hueConfigWatcher:stop() end
hueConfigWatcher = hs.pathwatcher.new(CONFIG_DIR, hueReloadConfig):start()

local function sendPulse(x, y, r, g, b, dur, radius)
  local msg = string.format(
    '{"type":"pulse","position":[%.3f,%.3f,0],"color":[%.3f,%.3f,%.3f],"duration":%.2f,"radius":%.2f%s}',
    x, y, r, g, b, dur, radius, hueTargetJson
  )
  udp:send(msg, "127.0.0.1", 9999)
end

function hueClearLights()
  udp:send('{"type":"clear"}', "127.0.0.1", 9999)
end

-- ── Enable/disable (persisted, callable via `hs -c`) ────────────────────
function hueIsEnabled()
  local f = io.open(ENABLED_FILE, "r")
  if not f then return true end  -- default: on
  local v = (f:read("*a") or ""):match("%S+")
  f:close()
  return v ~= "0"
end

function hueSetEnabled(on)
  local f = io.open(ENABLED_FILE, "w")
  if f then f:write(on and "1" or "0"); f:close() end
  if on then
    if hueKeyTap and not hueKeyTap:isEnabled() then hueKeyTap:start() end
    hs.alert.show("huetype: on", 0.8)
  else
    if hueKeyTap and hueKeyTap:isEnabled() then hueKeyTap:stop() end
    hueClearLights()
    hs.alert.show("huetype: off", 0.8)
  end
  return on
end

-- ── Event tap ───────────────────────────────────────────────────────────
local lastKeyTime = 0
local streak = 0
local keyStamps = {}  -- rolling window for WPM

if hueKeyTap then
  pcall(function() hueKeyTap:stop() end)
  hueKeyTap = nil
end
hueKeyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local kc = event:getKeyCode()
  local pos = keyPos[kc]
  if not pos then return false end

  local now = hs.timer.secondsSinceEpoch()

  -- Is this a character-producing key? Char-only accounting keeps WPM honest;
  -- all keys still pulse below so visual reactivity is unchanged.
  local is_char = not NON_TYPING_KEYS[kc]

  if is_char then
    -- update rolling window (for WPM)
    keyStamps[#keyStamps + 1] = now
    local kept = {}
    for _, ts in ipairs(keyStamps) do
      if now - ts < WPM_WINDOW then kept[#kept + 1] = ts end
    end
    keyStamps = kept

    -- streak
    if now - lastKeyTime < STREAK_GAP then
      streak = streak + 1
    else
      streak = 1
    end
    lastKeyTime = now
  end

  -- color from current palette + streak
  local pal = palettes[huePaletteIdx]
  local frac = math.min(streak - 1, STREAK_SPAN) / STREAK_SPAN
  local h = pal.h_start + frac * (pal.h_end - pal.h_start)
  local r, g, b = hcl2rgb(h, HCL_C, HCL_L)

  -- WPM → brightness multiplier (opt-in)
  local mult = 1.0
  if hueWpmEnabled() then
    -- WPM ≈ keys/5s * 60 / 5 (chars-per-word)  =  keys * 12/5
    local wpm = #keyStamps * 12 / WPM_WINDOW
    local norm = math.min(wpm, WPM_MAX) / WPM_MAX
    mult = WPM_MIN_BRIGHT + norm * (1 - WPM_MIN_BRIGHT)
  end
  if hueMode == "subtle" then mult = mult * SUBTLE_MULT end

  sendPulse(pos[1], pos[2], r * mult, g * mult, b * mult, PULSE_DURATION, PULSE_RADIUS)

  -- Live stats for huetype-tui (fire-and-forget; no listener → packet dropped).
  -- Only on char keys so the TUI's "typing" state matches real throughput.
  if is_char then
    udp:send(string.format(
      '{"streak":%d,"wpm_keys":%d,"streak_span":%d,"hue":%.1f}',
      streak, #keyStamps, STREAK_SPAN, h
    ), "127.0.0.1", 9998)
  end
  return false
end)
if hueIsEnabled() then hueKeyTap:start() end

local count = 0
for _ in pairs(keyPos) do count = count + 1 end
local state = hueIsEnabled() and "on" or "off"
hs.alert.show("hue-key loaded: " .. count .. " keys, " .. palettes[huePaletteIdx].name .. " (" .. state .. ")", 2)

