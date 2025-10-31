-- vulpes_greenish_dark colorscheme for Neovim
-- Generated with theme-lab

vim.cmd('hi clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.o.termguicolors = true
vim.g.colors_name = 'vulpes_greenish_dark'
vim.o.background = 'dark'

-- Helper function
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor colors
hi('Normal', { fg = '#7dff81', bg = '#0e0e0e' })
hi('Comment', { fg = '#39ac3d', italic = true })
hi('LineNr', { fg = '#595959' })
hi('CursorLine', { bg = '#1a1a1a' })
hi('CursorLineNr', { fg = '#23ff56', bold = true })
hi('Visual', { bg = '#595959' })
hi('Search', { bg = '#53ff09', fg = '#0e0e0e' })
hi('IncSearch', { bg = '#23ff56', fg = '#0e0e0e', bold = true })

-- Syntax highlighting
hi('Keyword', { fg = '#23ff56' })
hi('String', { fg = '#23ff65', italic = true })
hi('Number', { fg = '#6aff3c' })
hi('Boolean', { fg = '#6aff3c' })
hi('Function', { fg = '#ff098f' })
hi('Constant', { fg = '#19ff56' })
hi('Type', { fg = '#4cff10' })
hi('Identifier', { fg = '#07dc00' })
hi('Operator', { fg = '#23ff32' })
hi('Statement', { fg = '#23ff56' })
hi('Conditional', { fg = '#23ff56' })
hi('Repeat', { fg = '#23ff56' })
hi('Label', { fg = '#23ff56' })
hi('Special', { fg = '#19ff56' })
hi('PreProc', { fg = '#4cff10' })

-- LSP/Diagnostics
hi('DiagnosticError', { fg = '#0ecd00', underline = true })
hi('DiagnosticWarn', { fg = '#53ff09', underline = true })
hi('DiagnosticInfo', { fg = '#56ff5c' })
hi('DiagnosticHint', { fg = '#56ff5c' })

-- TreeSitter
hi('@keyword', { fg = '#23ff56' })
hi('@string', { fg = '#23ff65', italic = true })
hi('@number', { fg = '#6aff3c' })
hi('@function', { fg = '#ff098f' })
hi('@constant', { fg = '#19ff56' })
hi('@type', { fg = '#4cff10' })
hi('@variable', { fg = '#07dc00' })
hi('@operator', { fg = '#23ff32' })
hi('@comment', { fg = '#39ac3d', italic = true })

-- Git signs
hi('GitSignsAdd', { fg = '#00ef28' })
hi('GitSignsChange', { fg = '#2aff23' })
hi('GitSignsDelete', { fg = '#0ecd00' })
