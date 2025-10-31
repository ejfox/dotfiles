-- vulpes_greenish_light colorscheme for Neovim
-- Generated with theme-lab

vim.cmd('hi clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.o.termguicolors = true
vim.g.colors_name = 'vulpes_greenish_light'
vim.o.background = 'light'

-- Helper function
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor colors
hi('Normal', { fg = '#008504', bg = '#f4f4f4' })
hi('Comment', { fg = '#53c657', italic = true })
hi('LineNr', { fg = '#a6a6a6' })
hi('CursorLine', { bg = '#e6e6e6' })
hi('CursorLineNr', { fg = '#00cf30', bold = true })
hi('Visual', { bg = '#a6a6a6' })
hi('Search', { bg = '#41d900', fg = '#f4f4f4' })
hi('IncSearch', { bg = '#00cf30', fg = '#f4f4f4', bold = true })

-- Syntax highlighting
hi('Keyword', { fg = '#00cf30' })
hi('String', { fg = '#00e344', italic = true })
hi('Number', { fg = '#39f200' })
hi('Boolean', { fg = '#39f200' })
hi('Function', { fg = '#d90076' })
hi('Constant', { fg = '#00e83e' })
hi('Type', { fg = '#31c100' })
hi('Identifier', { fg = '#06b600' })
hi('Operator', { fg = '#00d90e' })
hi('Statement', { fg = '#00cf30' })
hi('Conditional', { fg = '#00cf30' })
hi('Repeat', { fg = '#00cf30' })
hi('Label', { fg = '#00cf30' })
hi('Special', { fg = '#00e83e' })
hi('PreProc', { fg = '#31c100' })

-- LSP/Diagnostics
hi('DiagnosticError', { fg = '#0a9d00', underline = true })
hi('DiagnosticWarn', { fg = '#41d900', underline = true })
hi('DiagnosticInfo', { fg = '#26ff2e' })
hi('DiagnosticHint', { fg = '#26ff2e' })

-- TreeSitter
hi('@keyword', { fg = '#00cf30' })
hi('@string', { fg = '#00e344', italic = true })
hi('@number', { fg = '#39f200' })
hi('@function', { fg = '#d90076' })
hi('@constant', { fg = '#00e83e' })
hi('@type', { fg = '#31c100' })
hi('@variable', { fg = '#06b600' })
hi('@operator', { fg = '#00d90e' })
hi('@comment', { fg = '#53c657', italic = true })

-- Git signs
hi('GitSignsAdd', { fg = '#00cf22' })
hi('GitSignsChange', { fg = '#08f200' })
hi('GitSignsDelete', { fg = '#0a9d00' })
