-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-enable soft wrap on markdown/text files
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ProseWrap", { clear = true }),
  pattern = { "markdown", "text" },
  callback = function()
    vim.wo.wrap = true
    vim.wo.linebreak = true
  end,
})

-- Check all plugin configs on startup (silent if OK, notify if broken)
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("CheckPlugins", { clear = true }),
  callback = function()
    local check_script = vim.fn.stdpath("config") .. "/check-plugins.sh"
    vim.fn.jobstart({ "bash", check_script }, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 1 and data[1] ~= "" then
          -- Show errors
          vim.notify(table.concat(data, "\n"), vim.log.levels.WARN)
        end
      end,
    })
  end,
})
