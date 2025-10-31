-- vulpes_reddish2_light colorscheme for Neovim
-- Generated with theme-lab

vim.cmd('hi clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.o.termguicolors = true
vim.g.colors_name = 'vulpes_reddish2_light'
vim.o.background = 'light'

-- Popup menu transparency
vim.o.pumblend = 13

-- Helper function
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor colors
hi('Normal', { fg = '#3b2b2b', bg = '#f7f7f7' })
hi('Comment', { fg = '#ff3737', italic = true })
hi('LineNr', { fg = '#a6a6a6' })
hi('CursorLine', { bg = '#e6e6e6' })
hi('CursorLineNr', { fg = '#e05a00', bold = true })
hi('Visual', { bg = '#a6a6a6' })
hi('Search', { bg = '#ea009c', fg = '#f7f7f7' })
hi('IncSearch', { bg = '#e05a00', fg = '#f7f7f7', bold = true })

-- Syntax highlighting
hi('Keyword', { fg = '#e05a00' })
hi('String', { fg = '#f48200', italic = true })
hi('Number', { fg = '#ff048a' })
hi('Boolean', { fg = '#ff048a' })
hi('Function', { fg = '#ea005e' })
hi('Constant', { fg = '#f97400' })
hi('Type', { fg = '#ef0050' })
hi('Identifier', { fg = '#fe0022' })
hi('Operator', { fg = '#ea1000' })
hi('Statement', { fg = '#e05a00' })
hi('Conditional', { fg = '#e05a00' })
hi('Repeat', { fg = '#e05a00' })
hi('Label', { fg = '#e05a00' })
hi('Special', { fg = '#f97400' })
hi('PreProc', { fg = '#ef0050' })

-- LSP/Diagnostics
hi('DiagnosticError', { fg = '#ea9c00', underline = true })
hi('DiagnosticWarn', { fg = '#ea009c', underline = true })
hi('DiagnosticInfo', { fg = '#ff3737' })
hi('DiagnosticHint', { fg = '#ff3737' })

-- TreeSitter
hi('@keyword', { fg = '#e05a00' })
hi('@string', { fg = '#f48200', italic = true })
hi('@number', { fg = '#ff048a' })
hi('@function', { fg = '#ea005e' })
hi('@constant', { fg = '#f97400' })
hi('@type', { fg = '#ef0050' })
hi('@variable', { fg = '#fe0022' })
hi('@operator', { fg = '#ea1000' })
hi('@comment', { fg = '#ff3737', italic = true })

-- Git signs
hi('GitSignsAdd', { fg = '#e03c00' })
hi('GitSignsChange', { fg = '#ff0426' })
hi('GitSignsDelete', { fg = '#ea9c00' })
