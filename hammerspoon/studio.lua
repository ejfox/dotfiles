-- STUDIO lock: the recording terminal opened by `studio` (a separate Ghostty instance,
-- pid in ~/.cache/studio/pid) keeps its exact size, so it can only move as a unit;
-- studio-recorder follows the window. The locked size is the w,h in ~/.cache/studio/rect.
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

local fixing = false
local function enforce(win)
  if fixing or not win or not win:application() or win:application():pid() ~= studioPid() then return end
  local w, h = lockedSize()
  if not w then return end
  local f = win:frame()
  if math.abs(f.w - w) < 1 and math.abs(f.h - h) < 1 then return end
  fixing = true
  local r = hs.geometry.rect(f.x, f.y, w, h)
  win:setFrame(r, 0)
  -- set again: crossing displays clamps the size to the screen it left
  hs.timer.doAfter(0.15, function() win:setFrame(r, 0); fixing = false end)
end

M.filter = hs.window.filter.new(false):setAppFilter("Ghostty", {})
M.filter:subscribe(hs.window.filter.windowMoved, enforce)
return M
