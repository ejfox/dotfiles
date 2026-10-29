-- tp7-unpublish: the "woops" button for TP-7 jams auto-published to music.tools.ejfox.com.
-- The vault's music-published.md has a ✕ remove link per upload:
--   hammerspoon://tp7-unpublish?key=music/tp7/<date>-<HHMM>.mp3
-- which runs `music tp7 unpublish <key>` (deletes it from R2, strikes the row, notifies).
-- announce() is how tp7-post.sh shows upload notifications: clicking one opens that list.
-- Everything runs as an async hs.task, so the hue-key event tap is never blocked.

local M = {}
local MUSIC = os.getenv("HOME") .. "/.dotfiles/bin/music"
local LIST = "obsidian://open?vault=ejfox&file=music-published"
M.live = {}   -- keep notification objects referenced so their click callbacks survive GC

function M.announce(title, text, sound)
  local n = hs.notify.new(function()
    hs.urlevent.openURL(LIST)
  end, { title = title, informativeText = text, soundName = sound, withdrawAfter = 0 })
  n:send()
  table.insert(M.live, n)
  if #M.live > 50 then table.remove(M.live, 1) end
end

hs.urlevent.bind("tp7-unpublish", function(_, params)
  local key = params and params.key or ""
  -- only TP-7 uploads; the pattern also rules out shell metacharacters
  if not key:match("^music/tp7/[%w%-]+%.mp3$") then
    hs.notify.new({ title = "TP-7 unpublish", informativeText = "Ignored a bad remove link: " .. key }):send()
    return
  end
  -- key goes in as an argument ($1), never spliced into the command string
  M.task = hs.task.new("/bin/zsh", nil, {
    "-c", 'export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"; exec "$0" tp7 unpublish "$1"', MUSIC, key })
  M.task:start()
end)

return M
