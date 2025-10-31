-- vulpes_reddish_dark colorscheme for Neovim
-- Generated with theme-lab

vim.cmd('hi clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.o.termguicolors = true
vim.g.colors_name = 'vulpes_reddish_dark'
vim.o.background = 'dark'

-- Helper function
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor colors
hi('Normal', { fg = '#ffe8e8', bg = '#121212' })
hi('Comment', { fg = '#ac3939', italic = true })
hi('LineNr', { fg = '#595959' })
hi('CursorLine', { bg = '#1a1a1a' })
hi('CursorLineNr', { fg = '#ff8b59', bold = true })
hi('Visual', { bg = '#595959' })
hi('Search', { bg = '#ff409f', fg = '#121212' })
hi('IncSearch', { bg = '#ff8b59', fg = '#121212', bold = true })

-- Syntax highlighting
hi('Keyword', { fg = '#ff8b59' })
hi('String', { fg = '#ff9c59', italic = true })
hi('Number', { fg = '#ff73ab' })
hi('Boolean', { fg = '#ff73ab' })
hi('Function', { fg = '#40adff' })
hi('Constant', { fg = '#ff8d4f' })
hi('Type', { fg = '#ff63a6' })
hi('Identifier', { fg = '#ff1c33' })
hi('Operator', { fg = '#ff6259' })
hi('Statement', { fg = '#ff8b59' })
hi('Conditional', { fg = '#ff8b59' })
hi('Repeat', { fg = '#ff8b59' })
hi('Label', { fg = '#ff8b59' })
hi('Special', { fg = '#ff8d4f' })
hi('PreProc', { fg = '#ff63a6' })

-- LSP/Diagnostics
hi('DiagnosticError', { fg = '#ff042a', underline = true })
hi('DiagnosticWarn', { fg = '#ff409f', underline = true })
hi('DiagnosticInfo', { fg = '#ff8c8c' })
hi('DiagnosticHint', { fg = '#ff8c8c' })

-- TreeSitter
hi('@keyword', { fg = '#ff8b59' })
hi('@string', { fg = '#ff9c59', italic = true })
hi('@number', { fg = '#ff73ab' })
hi('@function', { fg = '#40adff' })
hi('@constant', { fg = '#ff8d4f' })
hi('@type', { fg = '#ff63a6' })
hi('@variable', { fg = '#ff1c33' })
hi('@operator', { fg = '#ff6259' })
hi('@comment', { fg = '#ac3939', italic = true })

-- Git signs
hi('GitSignsAdd', { fg = '#ff5226' })
hi('GitSignsChange', { fg = '#ff596a' })
hi('GitSignsDelete', { fg = '#ff042a' })
