-- Keymaps: the ones EJ actually uses, ported from the LazyVim config.
-- Plugin-specific maps (picker, git, copilot) live next to their plugin.
local map = vim.keymap.set

-- Display-line j/k (counts stay exact for relativenumber jumps)
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = 'Down (display line)' })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = 'Up (display line)' })

map('n', '<Esc>', '<cmd>nohlsearch<cr><Esc>')
map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Write' })
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all' })
map('n', '<leader>bd', function() require('mini.bufremove').delete() end, { desc = 'Delete buffer' })

-- Native LSP navigation (same as main config: direct calls, no picker layer).
-- 0.12 already maps grn/gra/grr/gri/grt/gO/K by default.
map('n', 'gd', vim.lsp.buf.definition, { desc = 'Goto Definition' })
map('n', 'gr', vim.lsp.buf.references, { desc = 'Goto References', nowait = true })
map('n', 'gI', vim.lsp.buf.implementation, { desc = 'Goto Implementation' })
map('n', 'gy', vim.lsp.buf.type_definition, { desc = 'Goto Type Definition' })
map('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code action' })
map('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename' })
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line diagnostics' })

-- Yank selection with file path + line range (for pasting into Claude Code)
local function yank_with_path(path_mod, label)
  return function()
    local s, e = vim.fn.line('v'), vim.fn.line('.')
    if s > e then s, e = e, s end
    local code = table.concat(vim.fn.getline(s, e), '\n')
    vim.fn.setreg('+', string.format('%s:%d-%d\n```\n%s\n```', vim.fn.expand(path_mod), s, e, code))
    vim.notify('Copied with ' .. label .. ' path')
  end
end
map('x', '<leader>yr', yank_with_path('%:.', 'relative'), { desc = 'Yank with relative path' })
map('x', '<leader>ya', yank_with_path('%:p', 'absolute'), { desc = 'Yank with absolute path' })

-- Project .env
map('n', '<leader>fv', function()
  local root = vim.fs.root(0, { '.git' }) or vim.fn.getcwd()
  vim.cmd.edit(root .. '/.env')
end, { desc = 'Open project .env' })

-- Git jump: every hunk vs main into quickfix
map('n', '<leader>gj', function()
  local lines = vim.fn.systemlist('git jump --stdout diff main')
  if #lines == 0 then return vim.notify('No changes vs main') end
  vim.fn.setqflist({}, ' ', { title = 'Diff vs main', lines = lines })
  vim.cmd('copen')
end, { desc = 'Git jump vs main (quickfix)' })

map('n', '<leader>uw', function()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap
  vim.notify('Wrap ' .. (vim.wo.wrap and 'ON' or 'OFF'))
end, { desc = 'Toggle word wrap' })
