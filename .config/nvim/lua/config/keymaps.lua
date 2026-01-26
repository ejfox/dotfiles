-- ============================================================================
-- KEYMAPS
-- ============================================================================
-- Custom keybindings beyond LazyVim defaults.
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- ============================================================================
-- ZEN MODE
-- ============================================================================
-- WHY <leader>Z: Matches tmux C-a Z for consistency across tools

vim.keymap.set("n", "<leader>Z", "<cmd>ZenMode<cr>", { desc = "Zen Mode" })

-- ============================================================================
-- LSP NAVIGATION
-- ============================================================================
-- WHY native LSP instead of Telescope/Snacks: Direct calls are faster and
-- more reliable. Fuzzy finding is great for files, but LSP jumps should
-- be instant and predictable.

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Goto Definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Goto References" })
vim.keymap.set("n", "gI", vim.lsp.buf.implementation, { desc = "Goto Implementation" })
vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { desc = "Goto Type Definition" })

-- ============================================================================
-- LSP SYMBOLS & CALLS
-- ============================================================================
-- These are less common but useful for understanding large codebases

vim.keymap.set("n", "<leader>ss", vim.lsp.buf.document_symbol, { desc = "Document Symbols" })
vim.keymap.set("n", "<leader>sS", vim.lsp.buf.workspace_symbol, { desc = "Workspace Symbols" })
vim.keymap.set("n", "gai", vim.lsp.buf.incoming_calls, { desc = "Incoming Calls" })
vim.keymap.set("n", "gao", vim.lsp.buf.outgoing_calls, { desc = "Outgoing Calls" })
