-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Zen mode toggle (matches tmux Ctrl-a Z)
vim.keymap.set("n", "<leader>Z", "<cmd>ZenMode<cr>", { desc = "Zen Mode" })

-- Fix goto definition for Vue files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vue" },
  callback = function()
    local opts = { buffer = true, silent = true }
    
    -- Override gd for Vue files
    vim.keymap.set("n", "gd", function()
      -- Try vue-goto-definition first
      local ok = pcall(vim.cmd, "VueGotoDefinition")
      if not ok then
        -- Fallback to regular LSP definition
        vim.lsp.buf.definition()
      end
    end, vim.tbl_extend("force", opts, { desc = "Goto Definition (Vue)" }))
    
    -- Alternative keybinds
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Goto Declaration" }))
    vim.keymap.set("n", "<leader>gd", "<cmd>Telescope lsp_definitions<cr>", vim.tbl_extend("force", opts, { desc = "Goto Definition (Telescope)" }))
  end,
})
