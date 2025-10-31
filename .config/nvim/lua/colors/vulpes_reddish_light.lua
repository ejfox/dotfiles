-- vulpes_reddish_light colorscheme for Neovim
-- Generated with theme-lab

vim.cmd('hi clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.o.termguicolors = true
vim.g.colors_name = 'vulpes_reddish_light'
vim.o.background = 'light'

-- Helper function
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor colors
hi('Normal', { fg = '#c60000', bg = '#ebebeb' })
hi('Comment', { fg = '#c65353', italic = true })
hi('LineNr', { fg = '#a6a6a6' })
hi('CursorLine', { bg = '#e6e6e6' })
hi('CursorLineNr', { fg = '#a33100', bold = true })
hi('Visual', { bg = '#a6a6a6' })
hi('Search', { bg = '#ad0057', fg = '#ebebeb' })
hi('IncSearch', { bg = '#a33100', fg = '#ebebeb', bold = true })

-- Syntax highlighting
hi('Keyword', { fg = '#a33100' })
hi('String', { fg = '#b84900', italic = true })
hi('Number', { fg = '#c70050' })
hi('Boolean', { fg = '#c70050' })
hi('Function', { fg = '#0063ad' })
hi('Constant', { fg = '#bd4200' })
hi('Type', { fg = '#b3004d' })
hi('Identifier', { fg = '#94000f' })
hi('Operator', { fg = '#ad0900' })
hi('Statement', { fg = '#a33100' })
hi('Conditional', { fg = '#a33100' })
hi('Repeat', { fg = '#a33100' })
hi('Label', { fg = '#a33100' })
hi('Special', { fg = '#bd4200' })
hi('PreProc', { fg = '#b3004d' })

-- LSP/Diagnostics
hi('DiagnosticError', { fg = '#720011', underline = true })
hi('DiagnosticWarn', { fg = '#ad0057', underline = true })
hi('DiagnosticInfo', { fg = '#fa0000' })
hi('DiagnosticHint', { fg = '#fa0000' })

-- TreeSitter
hi('@keyword', { fg = '#a33100' })
hi('@string', { fg = '#b84900', italic = true })
hi('@number', { fg = '#c70050' })
hi('@function', { fg = '#0063ad' })
hi('@constant', { fg = '#bd4200' })
hi('@type', { fg = '#b3004d' })
hi('@variable', { fg = '#94000f' })
hi('@operator', { fg = '#ad0900' })
hi('@comment', { fg = '#c65353', italic = true })

-- Git signs
hi('GitSignsAdd', { fg = '#a32100' })
hi('GitSignsChange', { fg = '#c70014' })
hi('GitSignsDelete', { fg = '#720011' })
