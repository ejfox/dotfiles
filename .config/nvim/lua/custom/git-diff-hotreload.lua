-- Auto-refresh diffview when git changes (Claude Code commits)
local M = {}

local watcher = require("custom.directory-watcher")

function M.setup()
  -- Watch .git directory for changes
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("DiffviewGitWatch", { clear = true }),
    callback = function()
      -- Only setup watcher if diffview is loaded
      local ok, diffview = pcall(require, "diffview")
      if not ok then
        return
      end

      -- Watch .git directory
      local git_dir = vim.fn.finddir(".git", ".;")
      if git_dir ~= "" then
        watcher.watch_directory(git_dir, function()
          vim.schedule(function()
            -- Refresh diffview file list if it's open
            local ok, view = pcall(diffview.get_current_view)
            if ok and view and view.update_files then
              -- Call internal update function
              pcall(function()
                view:update_files()
              end)
            end
          end)
        end, { recursive = true, debounce = 300 })
      end

      -- Also watch for file changes in cwd (for untracked files)
      local cwd = vim.fn.getcwd()
      watcher.watch_directory(cwd, function()
        vim.schedule(function()
          local ok, view = pcall(diffview.get_current_view)
          if ok and view and view.update_files then
            pcall(function()
              view:update_files()
            end)
          end
        end)
      end, { recursive = true, debounce = 300 })
    end,
  })
end

return M
