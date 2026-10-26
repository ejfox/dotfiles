-- OBS on-air lights: OBS launches -> Office goes to the on-air look the iPhone LUT was tuned for
-- (key 5000K, warm practicals); OBS quits -> Office goes back to how it was.
-- All Hue logic (state save/restore, Office-only, never Pamara's room) lives in bin/office-lights.
local M = {}
local BIN = os.getenv("HOME") .. "/.dotfiles/bin/office-lights"
local OBS = "com.obsproject.obs-studio"

local function run(cmd)
  hs.task.new("/usr/bin/env", function(code, out, err)
    if code ~= 0 then print("obs-lights " .. cmd .. " failed: " .. (err or out or "")) end
  end, { "python3", BIN, cmd }):start()
end

-- obs-automute: mutes the SM7dB on Show · BRB / Show · Starting Soon (it waits for obs-websocket
-- itself and exits when OBS closes; terminate() on quit is belt and braces).
local AUTOMUTE = os.getenv("HOME") .. "/.dotfiles/bin/obs-automute"
local function startAutomute()
  if M.automute and M.automute:isRunning() then return end
  M.automute = hs.task.new("/usr/local/bin/python3", function(code, out, err)
    if code ~= 0 then print("obs-automute exited " .. code .. ": " .. (err or "")) end
  end, { AUTOMUTE })
  M.automute:start()
end

M.watcher = hs.application.watcher.new(function(_, event, app)
  if not app or app:bundleID() ~= OBS then return end
  if event == hs.application.watcher.launched then
    run("onair"); startAutomute()
  elseif event == hs.application.watcher.terminated then
    run("restore")
    if M.automute and M.automute:isRunning() then M.automute:terminate() end
  end
end):start()

-- OBS already open when Hammerspoon (re)loads: make sure the automute is running
if hs.application.get(OBS) then startAutomute() end

return M
