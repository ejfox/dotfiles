-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Zen mode toggle (matches tmux Ctrl-a Z)
vim.keymap.set("n", "<leader>Z", "<cmd>ZenMode<cr>", { desc = "Zen Mode" })

