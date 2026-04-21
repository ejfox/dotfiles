-- hue-key: every keypress → spatial color burst in the house lights
-- Sends UDP JSON to the hue-stream daemon on localhost:9999.

require("hs.ipc")  -- enables `hs -c "..."` CLI for debugging

-- ── Config ──────────────────────────────────────────────────────────────
local STREAK_GAP = 0.8       -- seconds of silence that resets streak
local STREAK_SPAN = 2400     -- keys to traverse hue journey start → end
local PULSE_DURATION = 0.4   -- per-key fade time
local PULSE_RADIUS = 2.0     -- spatial falloff — smaller = less light-bleed into adjacent rooms
local TARGETS_FILE = os.getenv("HOME") .. "/.config/hue-key/targets"

-- HCL journey: Lab/LCH is perceptually uniform, so equal streak steps feel equal.
-- Fixed L (luminance) and C (chroma) keep saturation/brightness constant;
-- only hue rotates, avoiding the RGB "muddy midpoint" problem.
local HCL_L = 42             -- luminance (0-100). Lower = darker / more saturated feel
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

local broadcastKeys = {
  [56]=true, [60]=true, [55]=true, [54]=true, [58]=true, [61]=true,
  [59]=true, [57]=true, [63]=true, [36]=true, [49]=true,
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

-- ── Target config (file-watched, live reload) ──────────────────────────
-- Edit ~/.config/hue-key/targets with comma-separated substrings.
-- Empty file = broadcast everywhere. Changes take effect on next keypress.
hueTargetJson = ''

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
  hs.alert.show("hue-key targets: " .. (content:gsub("[\r\n]", " ") or "(broadcast)"), 1.5)
end
hueLoadTargets()

-- Live reload on file change
if hueTargetsWatcher then hueTargetsWatcher:stop() end
hueTargetsWatcher = hs.pathwatcher.new(TARGETS_FILE, hueLoadTargets):start()

local function sendPulse(x, y, r, g, b, dur, radius)
  local msg = string.format(
    '{"type":"pulse","position":[%.3f,%.3f,0],"color":[%.3f,%.3f,%.3f],"duration":%.2f,"radius":%.2f%s}',
    x, y, r, g, b, dur, radius, hueTargetJson
  )
  udp:send(msg, "127.0.0.1", 9999)
  -- Debug log — tail /tmp/hue-key.log to see what's being sent
  local f = io.open("/tmp/hue-key.log", "a")
  if f then f:write(msg .. "\n"); f:close() end
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
