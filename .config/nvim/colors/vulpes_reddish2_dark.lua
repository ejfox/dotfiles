-- vulpes_reddish2_dark colorscheme for Neovim
-- Generated with theme-lab

vim.cmd('hi clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.o.termguicolors = true
vim.g.colors_name = 'vulpes_reddish2_dark'
vim.o.background = 'dark'

-- Popup menu transparency
vim.o.pumblend = 13

-- Helper function
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor colors
hi('Normal', { fg = '#e5dcdc', bg = '#000000' })
hi('Comment', { fg = '#c00000', italic = true })
hi('LineNr', { fg = '#595959' })
hi('CursorLine', { bg = '#1a1a1a' })
hi('CursorLineNr', { fg = '#ff6e0e', bold = true })
hi('Visual', { bg = '#595959' })
hi('Search', { bg = '#f300a2', fg = '#000000' })
hi('IncSearch', { bg = '#ff6e0e', fg = '#000000', bold = true })

-- Syntax highlighting
hi('Keyword', { fg = '#ff6e0e' })
hi('String', { fg = '#ff8e0e', italic = true })
hi('Number', { fg = '#ff279a' })
hi('Boolean', { fg = '#ff279a' })
hi('Function', { fg = '#f30061' })
hi('Constant', { fg = '#ff7903' })
hi('Type', { fg = '#ff1865' })
hi('Identifier', { fg = '#fd0022' })
hi('Operator', { fg = '#ff1e0e' })
hi('Statement', { fg = '#ff6e0e' })
hi('Conditional', { fg = '#ff6e0e' })
hi('Repeat', { fg = '#ff6e0e' })
hi('Label', { fg = '#ff6e0e' })
hi('Special', { fg = '#ff7903' })
hi('PreProc', { fg = '#ff1865' })

-- LSP/Diagnostics
hi('DiagnosticError', { fg = '#f3a200', underline = true })
hi('DiagnosticWarn', { fg = '#f300a2', underline = true })
hi('DiagnosticInfo', { fg = '#ff4141' })
hi('DiagnosticHint', { fg = '#ff4141' })

-- TreeSitter
hi('@keyword', { fg = '#ff6e0e' })
hi('@string', { fg = '#ff8e0e', italic = true })
hi('@number', { fg = '#ff279a' })
hi('@function', { fg = '#f30061' })
hi('@constant', { fg = '#ff7903' })
hi('@type', { fg = '#ff1865' })
hi('@variable', { fg = '#fd0022' })
hi('@operator', { fg = '#ff1e0e' })
hi('@comment', { fg = '#c00000', italic = true })

-- Git signs
hi('GitSignsAdd', { fg = '#da3a00' })
hi('GitSignsChange', { fg = '#ff0e2e' })
hi('GitSignsDelete', { fg = '#f3a200' })
