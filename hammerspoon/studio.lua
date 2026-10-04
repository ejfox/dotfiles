-- STUDIO lock: the recording terminal opened by `studio` (a separate Ghostty instance,
-- pid in ~/.cache/studio/pid) keeps its size and ratio, so it can only move as a unit;
-- studio-recorder follows the window. The locked size is the w,h in ~/.cache/studio/rect,
-- scaled down (ratio kept) on a screen too small for it.
local M = {}
local DIR = os.getenv("HOME") .. "/.cache/studio/"
local RECT = DIR .. "rect"

local function studioPid()
  local f = io.open(DIR .. "pid")
  if not f then return nil end
  local pid = tonumber(f:read("*l") or "")
  f:close()
  return pid
end

local function lockedSize()
  local f = io.open(RECT)
  if not f then return nil end
  local w, h = (f:read("*l") or ""):match("^%-?%d+,%-?%d+,(%d+),(%d+)$")
  f:close()
  if w then return tonumber(w), tonumber(h) end
end

-- The locked size, shrunk (same ratio) to fit the screen the window is on now:
-- a 1080x1920 window dragged onto the 1440pt-tall iMac becomes 810x1440, never squashed.
local function fitted(win, w, h)
  local s = (win:screen() or hs.screen.mainScreen()):frame()
  local k = math.min(1, s.w / w, s.h / h)
  w, h = math.floor(w * k), math.floor(h * k)
  local f = win:frame()
  local x = math.max(s.x, math.min(f.x, s.x + s.w - w))   -- keep it fully on that screen
  local y = math.max(s.y, math.min(f.y, s.y + s.h - h))
  return hs.geometry.rect(x, y, w, h)
end

local fixing = false
local function enforce(win)
  if fixing or not win or not win:application() or win:application():pid() ~= studioPid() then return end
  local w, h = lockedSize()
  if not w then return end
  local f, r = win:frame(), fitted(win, w, h)
  if math.abs(f.w - r.w) < 1 and math.abs(f.h - r.h) < 1 and math.abs(f.x - r.x) < 1 and math.abs(f.y - r.y) < 1 then return end
  fixing = true
  win:setFrame(r, 0)
  -- set again: crossing displays clamps the size to the screen it left
  hs.timer.doAfter(0.15, function() win:setFrame(r, 0); fixing = false end)
end

M.filter = hs.window.filter.new(false):setAppFilter("Ghostty", {})
M.filter:subscribe(hs.window.filter.windowMoved, enforce)
return M
