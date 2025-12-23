-- Directory watcher using Neovim's native fs_event API
-- Watches for file changes in cwd and triggers callbacks
local M = {}

local watchers = {}

-- Create filesystem watcher for a directory
function M.watch_directory(path, callback, opts)
  opts = opts or {}
  local recursive = opts.recursive or false
  local debounce_ms = opts.debounce or 100

  -- Debounce to avoid rapid-fire callbacks
  local timer = vim.uv.new_timer()
  local pending = false

  local function trigger_callback()
    if pending then
      return
    end
    pending = true
    timer:start(debounce_ms, 0, vim.schedule_wrap(function()
      pending = false
      callback()
    end))
  end

  -- Create fs_event handle
  local handle = vim.uv.new_fs_event()
  if not handle then
    vim.notify("Failed to create fs_event watcher for " .. path, vim.log.levels.ERROR)
    return nil
  end

  -- Start watching
  local flags = recursive and { recursive = true } or {}
  local success, err = handle:start(path, flags, function(err, filename, events)
    if err then
      vim.notify("Fs_event error: " .. err, vim.log.levels.ERROR)
      return
    end

    -- Ignore certain files/directories
    if filename and (
      filename:match("%.git/") or
      filename:match("node_modules/") or
      filename:match("%.swp$") or
      filename:match("%.tmp$")
    ) then
      return
    end

    trigger_callback()
  end)

  if not success then
    vim.notify("Failed to start fs_event: " .. (err or "unknown"), vim.log.levels.ERROR)
    return nil
  end

  -- Store watcher for cleanup
  table.insert(watchers, { handle = handle, timer = timer })

  return handle
end

-- Stop all watchers
function M.stop_all()
  for _, watcher in ipairs(watchers) do
    if watcher.handle and not watcher.handle:is_closing() then
      watcher.handle:stop()
      watcher.handle:close()
    end
    if watcher.timer and not watcher.timer:is_closing() then
      watcher.timer:stop()
      watcher.timer:close()
    end
  end
  watchers = {}
end

return M
