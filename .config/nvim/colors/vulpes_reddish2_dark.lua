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
hi('Normal', { fg = '#e5dcdc', bg = '#0d0d0d' })
hi('Comment', { fg = '#c00000', italic = true })

-- Line numbers (ultra-subtle - barely visible)
hi('LineNr', { fg = '#1f1f1f' })  -- 8% mix of bg+fg, ultra subtle
hi('LineNrAbove', { fg = '#1f1f1f' })
hi('LineNrBelow', { fg = '#1f1f1f' })
hi('CursorLineNr', { fg = '#ff1865', bold = true })  -- Current line stands out

-- UI Chrome
hi('CursorLine', { bg = '#1a1a1a' })
hi('SignColumn', { bg = '#0d0d0d' })  -- Match main bg
hi('FoldColumn', { fg = '#1f1f1f', bg = '#0d0d0d' })  -- Subtle
hi('VertSplit', { fg = '#1a1a1a' })  -- Subtle splits
hi('WinSeparator', { fg = '#1a1a1a' })

hi('Visual', { bg = '#3d1a2a' })  -- Subtle red-tinted selection for palette cohesion
hi('Search', { bg = '#f300a2', fg = '#0d0d0d' })
hi('IncSearch', { bg = '#ff1865', fg = '#0d0d0d', bold = true })

-- Matching brackets (important for navigation)
hi('MatchParen', { fg = '#ff1865', bg = '#262626', bold = true })

-- Color column for width guides
hi('ColorColumn', { bg = '#1a1a1a' })
hi('Folded', { fg = '#c00000', bg = '#1a1a1a' })

-- Indent guides (barely visible)
hi('IndentBlanklineChar', { fg = '#1a1a1a', nocombine = true })  -- Ultra subtle
hi('IndentBlanklineContextChar', { fg = '#262626', nocombine = true })  -- Slightly more visible
hi('IblIndent', { fg = '#1a1a1a', nocombine = true })  -- For ibl v3
hi('IblScope', { fg = '#262626', nocombine = true })

-- Non-text elements (keep out of the way)
hi('NonText', { fg = '#1f1f1f' })
hi('SpecialKey', { fg = '#1f1f1f' })
hi('Whitespace', { fg = '#1a1a1a' })
hi('EndOfBuffer', { fg = '#0d0d0d' })  -- Invisible

-- Syntax highlighting
hi('Keyword', { fg = '#ff1865' })  -- Red-pink
hi('String', { fg = '#ff279a', italic = true })  -- Magenta
hi('Number', { fg = '#ff279a' })
hi('Boolean', { fg = '#ff279a' })
hi('Function', { fg = '#f30061' })
hi('Constant', { fg = '#ff1865' })  -- Red-pink
hi('Type', { fg = '#ff1865' })
hi('Identifier', { fg = '#fd0022' })
hi('Operator', { fg = '#ff1e0e' })
hi('Statement', { fg = '#ff1865' })  -- Red-pink
hi('Conditional', { fg = '#ff1865' })  -- Red-pink
hi('Repeat', { fg = '#ff1865' })  -- Red-pink
hi('Label', { fg = '#ff1865' })  -- Red-pink
hi('Special', { fg = '#ff1865' })  -- Red-pink
hi('PreProc', { fg = '#ff1865' })

-- LSP/Diagnostics (semantic colors, no oranges)
hi('DiagnosticError', { fg = '#ff0e2e', underline = true })  -- Red for errors
hi('DiagnosticWarn', { fg = '#f300a2', underline = true })   -- Magenta for warnings
hi('DiagnosticInfo', { fg = '#ff279a', underline = true })   -- Pink for info
hi('DiagnosticHint', { fg = '#c00000' })  -- Muted red for hints

-- TreeSitter
hi('@keyword', { fg = '#ff1865' })  -- Red-pink
hi('@string', { fg = '#ff279a', italic = true })  -- Magenta
hi('@number', { fg = '#ff279a' })
hi('@function', { fg = '#f30061' })
hi('@constant', { fg = '#ff1865' })  -- Red-pink
hi('@type', { fg = '#ff1865' })
hi('@variable', { fg = '#fd0022' })
hi('@operator', { fg = '#ff1e0e' })
hi('@comment', { fg = '#c00000', italic = true })

-- Git signs (red/pink palette, no oranges)
hi('GitSignsAdd', { fg = '#ff279a' })     -- Magenta for additions
hi('GitSignsChange', { fg = '#f30061' })  -- Pink for changes
hi('GitSignsDelete', { fg = '#fd0022' })  -- Red for deletions

-- Statusline (inactive should be very subtle)
hi('StatusLine', { fg = '#e5dcdc', bg = '#1a1a1a' })
hi('StatusLineNC', { fg = '#262626', bg = '#0d0d0d' })  -- Much more subtle

-- Popup menus (floats)
hi('Pmenu', { fg = '#e5dcdc', bg = '#1a1a1a' })
hi('PmenuSel', { fg = '#0d0d0d', bg = '#ff1865' })
hi('PmenuSbar', { bg = '#1a1a1a' })
hi('PmenuThumb', { bg = '#ff1865' })

-- Floating windows
hi('NormalFloat', { fg = '#e5dcdc', bg = '#1a1a1a' })
hi('FloatBorder', { fg = '#3a3a3a', bg = '#1a1a1a' })

-- File explorers (blend with main bg)
hi('NvimTreeNormal', { fg = '#e5dcdc', bg = '#0d0d0d' })
hi('NvimTreeEndOfBuffer', { fg = '#0d0d0d' })
hi('NeoTreeNormal', { fg = '#e5dcdc', bg = '#0d0d0d' })
hi('NeoTreeEndOfBuffer', { fg = '#0d0d0d' })
