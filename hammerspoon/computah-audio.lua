-- computah-audio: menu bar control for the Windows PC (computah) audio.
-- Mute/unmute the machine and nudge its volume from the Mac, over SSH — works
-- regardless of how the PC's sound reaches these speakers (VBAN stream, Moonlight,
-- etc.). Drives farm ~/pc-audio.ps1 via the `computah run` CLI (media keys, no
-- window; komorebi already ignores console popups).
local M = {}
local COMPUTAH = os.getenv("HOME") .. "/.dotfiles/bin/computah"

-- fire a pc-audio.ps1 action without blocking Hammerspoon
local function pc(action, n)
  local fmt = "%s run 'powershell -NoProfile -ExecutionPolicy Bypass -File %%USERPROFILE%%\\pc-audio.ps1 %s %d' >/dev/null 2>&1 &"
  hs.execute(string.format(fmt, COMPUTAH, action, n or 1), true)  -- true = user login shell (PATH)
end

local muted = false
local mb = hs.menubar.new()
if mb then
  local function redraw() mb:setTitle(muted and "◌" or "◉") end   -- ◉ live · ◌ muted (glyphs, no emoji)
  redraw()
  mb:setTooltip("computah audio — Windows machine")
  mb:setMenu(function()
    return {
      { title = (muted and "Unmute" or "Mute") .. " Windows machine",
        fn = function() pc("mute"); muted = not muted; redraw() end },
      { title = "-" },
      { title = "Volume  +", fn = function() pc("up", 3) end },
      { title = "Volume  −", fn = function() pc("down", 3) end },
      { title = "fine +",    fn = function() pc("up", 1) end },
      { title = "fine −",    fn = function() pc("down", 1) end },
    }
  end)
end
M.menubar = mb
return M
