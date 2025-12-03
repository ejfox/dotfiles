-- Hot reload buffers when files change externally (Claude Code editing)
-- Reloads on: FocusGained, TermLeave, BufEnter, WinEnter, CursorHold, CursorHoldI
-- Also watches filesystem for changes in cwd
local M = {}

local watcher = require("custom.directory-watcher")

-- Check if buffer should be reloaded
local function should_reload_buffer(bufnr)
  -- Skip if buffer is modified (don't lose unsaved work)
  if vim.api.nvim_buf_get_option(bufnr, "modified") then
    return false
  end

  -- Skip special buffers (diffview, neo-tree, etc)
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  if buftype ~= "" then
    return false
  end

  -- Skip if no file backing
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    return false
  end

  -- Only reload if file exists
  if vim.fn.filereadable(filepath) ~= 1 then
    return false
  end

  return true
end

-- Reload visible buffers in current tab
local function reload_visible_buffers()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(current_tab)

  for _, win in ipairs(windows) do
    local bufnr = vim.api.nvim_win_get_buf(win)

    if should_reload_buffer(bufnr) then
      -- Check if file changed on disk
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("checktime")
      end)
    end
  end
end

-- Setup autocmds for reload events
function M.setup()
  -- Reload on various events
  vim.api.nvim_create_autocmd({
    "FocusGained",     -- When nvim gets focus
    "TermLeave",       -- Leaving terminal mode
    "BufEnter",        -- Entering buffer
    "WinEnter",        -- Entering window
    "CursorHold",      -- Cursor idle (normal mode)
    "CursorHoldI",     -- Cursor idle (insert mode)
  }, {
    group = vim.api.nvim_create_augroup("HotReload", { clear = true }),
    callback = function()
      reload_visible_buffers()
    end,
  })

  -- Watch filesystem for changes in cwd
  local cwd = vim.fn.getcwd()
  watcher.watch_directory(cwd, function()
    vim.schedule(function()
      reload_visible_buffers()
    end)
  end, { recursive = true, debounce = 200 })

  -- Notify and flag when files reload
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = vim.api.nvim_create_augroup("HotReloadNotify", { clear = true }),
    callback = function()
      vim.notify("📝 File reloaded (Claude Code edit)", vim.log.levels.INFO)

      -- Set flag for statusline indicator
      vim.g.file_just_reloaded = true

      -- Clear flag after 5 seconds
      vim.defer_fn(function()
        vim.g.file_just_reloaded = false
      end, 5000)
    end,
  })

  -- Re-watch cwd if it changes
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("HotReloadDirChange", { clear = true }),
    callback = function()
      watcher.stop_all()
      local new_cwd = vim.fn.getcwd()
      watcher.watch_directory(new_cwd, function()
        vim.schedule(function()
          reload_visible_buffers()
        end)
      end, { recursive = true, debounce = 200 })
    end,
  })
end

return M
