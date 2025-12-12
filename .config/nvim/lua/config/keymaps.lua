-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Zen mode toggle (matches tmux Ctrl-a Z)
vim.keymap.set("n", "<leader>Z", "<cmd>ZenMode<cr>", { desc = "Zen Mode" })

-- LSP navigation - override snacks_picker extra with native LSP calls
-- (snacks_picker had reliability issues, prefer direct LSP protocol)
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Goto Definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Goto References" })
vim.keymap.set("n", "gI", vim.lsp.buf.implementation, { desc = "Goto Implementation" })
vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { desc = "Goto Type Definition" })

-- LSP symbols and calls - also using native instead of snacks
vim.keymap.set("n", "<leader>ss", vim.lsp.buf.document_symbol, { desc = "Document Symbols" })
vim.keymap.set("n", "<leader>sS", vim.lsp.buf.workspace_symbol, { desc = "Workspace Symbols" })
vim.keymap.set("n", "gai", vim.lsp.buf.incoming_calls, { desc = "Incoming Calls" })
vim.keymap.set("n", "gao", vim.lsp.buf.outgoing_calls, { desc = "Outgoing Calls" })

-- Disable treesitter class navigation - we use ]c/[c for git diffs
-- (mappings don't exist by default, so skip the delete)

