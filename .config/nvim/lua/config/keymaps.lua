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

-- ============================================================================
-- DISPLAY-LINE MOTION
-- ============================================================================
-- WHY: usage logs show `gjgjgj…` and `gkgkgk…` as the #1 and #3 most-repeated
-- key sequences (wrap=true is on but j/k moved by logical line). Make j/k move
-- by DISPLAY line; the v:count==0 guard keeps 10j / relativenumber jumps exact.
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down (display line)" })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up (display line)" })

-- ============================================================================
-- PROJECT .env JUMP
-- ============================================================================
-- WHY: .env opened 9× across projects — a recurring "where are my keys" reach.
-- Roots to the git dir so it works uniformly across newswell/website2/metro.
vim.keymap.set("n", "<leader>fe", function()
  local root = vim.fs.root(0, { ".git" }) or vim.fn.getcwd()
  vim.cmd.edit(root .. "/.env")
end, { desc = "Open project .env" })

-- ============================================================================
-- GIT DIFF NAVIGATION
-- ============================================================================
-- Jump across ALL changed files vs main (loads into quickfix, use ]q/[q)

vim.keymap.set("n", "<leader>gj", function()
  local lines = vim.fn.systemlist("git jump --stdout diff main")
  if #lines == 0 then
    vim.notify("No changes vs main")
    return
  end
  vim.fn.setqflist({}, " ", { title = "Diff vs main", lines = lines })
  vim.cmd("copen")
end, { desc = "Git jump vs main (quickfix)" })
