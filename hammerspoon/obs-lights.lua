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

M.watcher = hs.application.watcher.new(function(_, event, app)
  if not app or app:bundleID() ~= OBS then return end
  if event == hs.application.watcher.launched then run("onair")
  elseif event == hs.application.watcher.terminated then run("restore") end
end):start()

return M
