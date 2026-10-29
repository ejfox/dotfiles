-- ============================================================================
-- KEYMAPS
-- ============================================================================
-- Custom keybindings beyond LazyVim defaults.
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- ============================================================================
-- ZEN MODE
-- ============================================================================
-- WHY <leader>Z: Matches tmux C-a Z for consistency across tools

-- (mapped in lua/plugins/focus.lua via Snacks.zen)

-- LSP keys (gd, gr, gI, gy, <leader>ss/sS, gai/gao) come from LazyVim, which
-- sets them per buffer on LspAttach; global maps here were always overridden.

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
-- WHY <leader>fv not <leader>fe: <leader>fe/<leader>e are claimed by the
-- snacks_explorer LazyVim extra (Explorer Snacks, root dir).
vim.keymap.set("n", "<leader>fv", function()
  local root = vim.fs.root(0, { ".git" }) or vim.fn.getcwd()
  vim.cmd.edit(root .. "/.env")
end, { desc = "Open project .env" })


-- ============================================================================
-- YANK WITH PATH (for pasting into Claude Code)
-- ============================================================================
-- Copies the selection as `path:start-end` plus a fenced block.
-- WHY min/max: line("v") is below line(".") when you select upward.

local function yank_with_path(path_fmt)
  return function()
    local a, b = vim.fn.line("v"), vim.fn.line(".")
    local first, last = math.min(a, b), math.max(a, b)
    local code = table.concat(vim.fn.getline(first, last), "\n")
    local path = vim.fn.expand(path_fmt)
    vim.fn.setreg("+", string.format("%s:%d-%d\n```\n%s\n```", path, first, last, code))
    vim.notify("Copied with path: " .. path)
  end
end

vim.keymap.set("v", "<leader>yr", yank_with_path("%:."), { desc = "Yank with relative path" })
vim.keymap.set("v", "<leader>ya", yank_with_path("%:p"), { desc = "Yank with absolute path" })

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
