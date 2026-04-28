-- vulpes-reddishnovember-light colorscheme
-- Light Vulpes 2.0 — Risograph Editorial
-- Direct translation of vulpes-reddishnovember-dark.lua, preserving the system:
--   • pink dominates (brand, syntax)
--   • TEAL is the inverse hue (comments, errors, search) — NOT muted pink
--   • pure-WHITE-spotlight in dark becomes pure-BLACK-spotlight in light (functions)
--   • diff colors are HCL-harmonized (chartreuse + burgundy duo, vulpes hue ~340°)
--   • bloom-safe: bloom shader is red-selective, so teal/tan highlights survive
-- Reference: ~/code/VULPES/vulpes-theme-lab/themes/light-vulpes-v2/

local M = {}

function M.setup()
  vim.cmd('hi clear')
  if vim.fn.exists('syntax_on') then
    vim.cmd('syntax reset')
  end

  vim.o.background = 'light'
  vim.g.colors_name = 'vulpes-reddishnovember-light'

  local colors = {
    -- Surface — pure white (mirrors dark's #000000 OLED black)
    -- v2.5: returning to white. Warm tones step UP for raised surfaces.
    bg = '#ffffff',
    bg_alt = '#ebe2d6',
    fg = '#1a0f14',          -- warm dark ink (substitutes for soft pink-cream)
    base = '#a8003c',        -- brand pink, darkened from #e60067 for cream

    -- Diagnostics — preserve the teal-as-inverse-hue rule
    error = '#0a4d52',       -- deep teal (was #a0f7fc bright teal — same hue, darkened)
    warning = '#8a5530',     -- sepia (was #ffaa00 — same warm hue, darkened for cream)
    success = '#000000',     -- pure black (was #ffffff — pure-spotlight inversion)
    info = '#a8003c',        -- brand pink (was #ff0095)
    hint = '#5c0030',        -- deeper wine (was #ff4d9d)

    -- Diff colors (HCL-harmonized with vulpes base hue ~340°, for cream bg)
    -- chroma-verified: all pass AA on cream bg (was #5d7a1f failing at 4.24:1)
    diff_add = '#4d6618',    -- darkened chartreuse (was #b4d455 — same hue, AA on cream)
    diff_delete = '#a8003c', -- vulpes accent.strong (matches delta minus-style)
    diff_change = '#8a5530', -- sepia for changes (was #ffaa00 — same warm hue)
    diff_text = '#7a3055',   -- muted vulpes for changed text (was #e8b4c8)

    -- Comments — TEAL (the system's deliberate inverse-hue, NOT muted pink)
    comment = '#1a5e6e',     -- deep teal (was #6eedf7 bright teal — same hue, darkened)
    linenr = '#6a5d60',      -- muted ink-grey (was #735865)

    -- Syntax — pink family with chroma variation (preserve dark's logic)
    keyword = '#7a0044',     -- magenta-leaning (was #ff1aca)
    string = '#1a0f14',      -- near-black ink — strings READ as content (was #f5f5f5)
    number = '#a8003c',      -- (was #ff33c5)
    boolean = '#5c0030',     -- deep wine (was #ff1043)
    func = '#000000',        -- PURE BLACK SPOTLIGHT (was pure white — methods stand out)
    const = '#5c0030',       -- (was #ff1043)
    type = '#7a0044',        -- (was #ff24ab)
    variable = '#a8003c',    -- (was #ff0a89)
    operator = '#7a3055',    -- muted vulpes (was #f92c7a)
    builtin = '#5c0030',     -- (was #f82956)
    parameter = '#7a3055',   -- (was #ff057e)
    property = '#a8003c',    -- (was #ff0a91)
    namespace = '#7a3055',   -- (was #f8326e)
    macro = '#7a0044',       -- (was #f92a9c)
    tag = '#a8003c',         -- (was #f82e64)
    punctuation = '#3d2a30', -- toned to L4 ink — punctuation is chrome (was #f82470)
    heading = '#5c0030',     -- (was #ff2453)

    -- Selection — bloom-safe (bloom is red-selective, warm tan survives)
    -- Dark used dark teal bg + white fg; light uses warm tan bg + dark ink fg
    -- (same "subtle inverse step on base surface" intent)
    selection = '#e0d4be',
    selection_fg = '#1a0f14',
    cursor = '#a8003c',
    cursorline = '#f5efe5',  -- subtle warm step from white (was #2a1520 in dark)
  }

  local highlights = {
    -- ============================================================================
    -- EDITOR UI
    -- ============================================================================
    Normal = { fg = colors.fg, bg = 'none' },
    NormalFloat = { fg = colors.fg, bg = colors.bg_alt },
    NormalNC = { fg = colors.fg, bg = 'none' },
    FloatBorder = { fg = colors.base, bg = colors.bg_alt },
    FloatTitle = { fg = colors.base, bg = colors.bg_alt },

    Cursor = { fg = colors.bg, bg = colors.cursor },
    lCursor = { link = 'Cursor' },
    CursorIM = { link = 'Cursor' },
    TermCursor = { link = 'Cursor' },
    TermCursorNC = { fg = colors.bg, bg = colors.comment },

    CursorLine = { bg = colors.cursorline },
    CursorColumn = { bg = colors.cursorline },
    CursorLineNr = { fg = colors.base },
    LineNr = { fg = colors.linenr },
    LineNrAbove = { fg = colors.linenr },
    LineNrBelow = { fg = colors.linenr },

    SignColumn = { bg = 'none' },
    SignColumnSB = { link = 'SignColumn' },
    FoldColumn = { fg = colors.comment, bg = 'none' },
    Folded = { fg = colors.comment, bg = colors.bg_alt },
    ColorColumn = { bg = colors.bg_alt },

    -- Selections & Search (teal-family — bloom-safe since bloom is red-selective)
    -- Dark: Visual=dark-teal/white, Search=dark-teal/bright-teal, IncSearch=bright-teal/black
    -- Light: Visual=warm-tan/ink, Search=pale-teal/deep-teal, IncSearch=deep-teal/cream
    Visual = { fg = colors.selection_fg, bg = colors.selection },
    VisualNOS = { fg = colors.selection_fg, bg = colors.selection },
    Search = { fg = '#1a5e6e', bg = '#c5d8da' },
    IncSearch = { fg = colors.bg, bg = '#1a5e6e' },
    CurSearch = { fg = colors.bg, bg = '#1a5e6e' },
    Substitute = { fg = colors.bg, bg = colors.error },

    -- UI Elements
    Pmenu = { fg = colors.fg, bg = colors.bg_alt },
    PmenuSel = { fg = '#faf6ee', bg = '#5c0030' },  -- mirrors dark (was #ffffff/#5c0030)
    PmenuSbar = { bg = colors.bg_alt },
    PmenuThumb = { bg = colors.base },
    PmenuKind = { fg = colors.type, bg = colors.bg_alt },
    PmenuKindSel = { fg = colors.bg, bg = colors.type },
    PmenuExtra = { fg = colors.comment, bg = colors.bg_alt },
    PmenuExtraSel = { fg = colors.bg, bg = colors.comment },

    StatusLine = { fg = colors.fg, bg = colors.bg_alt },
    StatusLineNC = { fg = colors.linenr, bg = 'none' },  -- linenr-grey, NOT comment-teal
    WinBar = { fg = colors.fg, bg = 'none' },
    WinBarNC = { fg = colors.linenr, bg = 'none' },

    TabLine = { fg = colors.linenr, bg = 'none' },
    TabLineFill = { bg = 'none' },
    TabLineSel = { fg = colors.base, bg = colors.bg_alt, bold = true },

    -- BufferLine (active buffer = pink text, inactive = muted) — mirrors dark
    BufferLineBufferSelected = { fg = colors.base, bg = colors.bg_alt, bold = true },
    BufferLineIndicatorSelected = { fg = colors.base },
    BufferLineBuffer = { fg = colors.linenr, bg = 'none' },
    BufferLineBackground = { fg = colors.linenr, bg = 'none' },
    BufferLineFill = { bg = 'none' },
    BufferLineTab = { fg = colors.linenr, bg = 'none' },
    BufferLineTabSelected = { fg = colors.base, bg = colors.bg_alt, bold = true },
    BufferLineTabClose = { fg = colors.linenr, bg = 'none' },
    BufferLineSeparator = { fg = colors.bg, bg = 'none' },
    BufferLineSeparatorSelected = { fg = colors.bg, bg = 'none' },
    BufferLineSeparatorVisible = { fg = colors.bg, bg = 'none' },
    BufferLineModified = { fg = colors.base },
    BufferLineModifiedSelected = { fg = colors.base, bold = true },

    VertSplit = { fg = colors.bg_alt },
    WinSeparator = { fg = colors.bg_alt },

    Title = { fg = colors.base },
    Directory = { fg = '#7a3055' },  -- muted vulpes (mirrors dark's #c490a8 — bloom-friendly)
    Question = { fg = colors.success },
    MoreMsg = { fg = colors.success },
    ModeMsg = { fg = colors.base },
    WarningMsg = { fg = colors.warning },
    ErrorMsg = { fg = colors.error },

    Conceal = { fg = colors.comment },
    NonText = { fg = colors.comment },
    SpecialKey = { fg = colors.comment },
    Whitespace = { fg = '#d8cbb8' },  -- dimmer than comments (mirrors dark's #2a2030)
    EndOfBuffer = { fg = 'none' },

    -- Matching brackets
    MatchParen = { fg = colors.warning, bg = '#e8d8c5', bold = true },

    -- Spell checking
    SpellBad = { sp = colors.error, undercurl = true },
    SpellCap = { sp = colors.warning, undercurl = true },
    SpellLocal = { sp = colors.info, undercurl = true },
    SpellRare = { sp = colors.hint, undercurl = true },

    -- ============================================================================
    -- CORE SYNTAX HIGHLIGHTING
    -- ============================================================================
    Comment = { fg = colors.comment, italic = true },
    SpecialComment = { fg = colors.comment, italic = true },

    Constant = { fg = colors.const },
    String = { fg = colors.string },
    Character = { fg = colors.string },
    Number = { fg = colors.number },
    Boolean = { fg = colors.boolean },
    Float = { fg = colors.number },

    Identifier = { fg = colors.variable },
    Function = { fg = colors.func },

    Statement = { fg = colors.keyword },
    Conditional = { fg = colors.keyword },
    Repeat = { fg = colors.keyword },
    Label = { fg = colors.keyword },
    Operator = { fg = colors.operator },
    Keyword = { fg = colors.keyword },
    Exception = { fg = colors.error },

    PreProc = { fg = colors.base },
    Include = { fg = colors.keyword },
    Define = { fg = colors.keyword },
    Macro = { fg = colors.macro },
    PreCondit = { fg = colors.keyword },

    Type = { fg = colors.type },
    StorageClass = { fg = colors.keyword },
    Structure = { fg = colors.type },
    Typedef = { fg = colors.type },

    Special = { fg = colors.base },
    SpecialChar = { fg = colors.base },
    Tag = { fg = colors.tag },
    Delimiter = { fg = colors.punctuation },
    Debug = { fg = colors.warning },

    Underlined = { underline = true },
    Bold = { bold = true },
    Italic = { italic = true },

    Ignore = { fg = colors.linenr },
    Error = { fg = colors.error },
    Todo = { fg = colors.bg, bg = colors.warning },

    -- ============================================================================
    -- LSP DIAGNOSTICS
    -- ============================================================================
    DiagnosticError = { fg = colors.error },
    DiagnosticWarn = { fg = colors.warning },
    DiagnosticInfo = { fg = colors.info },
    DiagnosticHint = { fg = colors.hint },
    DiagnosticOk = { fg = colors.success },

    DiagnosticVirtualTextError = { fg = colors.error, bg = 'none' },
    DiagnosticVirtualTextWarn = { fg = colors.warning, bg = 'none' },
    DiagnosticVirtualTextInfo = { fg = colors.info, bg = 'none' },
    DiagnosticVirtualTextHint = { fg = colors.hint, bg = 'none' },

    DiagnosticUnderlineError = { sp = colors.error, undercurl = true },
    DiagnosticUnderlineWarn = { sp = colors.warning, underline = true },
    DiagnosticUnderlineInfo = { sp = colors.info, underline = true },
    DiagnosticUnderlineHint = { sp = colors.hint, underline = true },

    DiagnosticFloatingError = { fg = colors.error, bg = colors.bg_alt },
    DiagnosticFloatingWarn = { fg = colors.warning, bg = colors.bg_alt },
    DiagnosticFloatingInfo = { fg = colors.info, bg = colors.bg_alt },
    DiagnosticFloatingHint = { fg = colors.hint, bg = colors.bg_alt },

    DiagnosticSignError = { fg = colors.error, bg = 'none' },
    DiagnosticSignWarn = { fg = colors.warning, bg = 'none' },
    DiagnosticSignInfo = { fg = colors.info, bg = 'none' },
    DiagnosticSignHint = { fg = colors.hint, bg = 'none' },

    -- LSP References (highlight symbol under cursor) — light-tinted versions
    LspReferenceText = { bg = '#e8dcc8' },
    LspReferenceRead = { bg = '#e8dcc8' },
    LspReferenceWrite = { bg = '#dfcfb0' },  -- slightly darker for writes (mirrors dark)

    -- LSP Semantic Token Groups
    ['@lsp.type.class'] = { link = 'Type' },
    ['@lsp.type.decorator'] = { link = 'Function' },
    ['@lsp.type.enum'] = { link = 'Type' },
    ['@lsp.type.enumMember'] = { link = 'Constant' },
    ['@lsp.type.function'] = { link = 'Function' },
    ['@lsp.type.interface'] = { link = 'Type' },
    ['@lsp.type.macro'] = { link = 'Macro' },
    ['@lsp.type.method'] = { link = 'Function' },
    ['@lsp.type.namespace'] = { fg = colors.namespace },
    ['@lsp.type.parameter'] = { fg = colors.parameter },
    ['@lsp.type.property'] = { fg = colors.property },
    ['@lsp.type.struct'] = { link = 'Type' },
    ['@lsp.type.type'] = { link = 'Type' },
    ['@lsp.type.typeParameter'] = { link = 'Type' },
    ['@lsp.type.variable'] = { link = '@variable' },

    -- ============================================================================
    -- TREESITTER - COMPREHENSIVE LANGUAGE SUPPORT
    -- ============================================================================

    -- Comments
    ['@comment'] = { link = 'Comment' },
    ['@comment.documentation'] = { fg = colors.comment },
    ['@comment.error'] = { fg = colors.error },
    ['@comment.warning'] = { fg = colors.warning },
    ['@comment.todo'] = { fg = colors.bg, bg = colors.warning },
    ['@comment.note'] = { fg = colors.info },

    -- Constants
    ['@constant'] = { link = 'Constant' },
    ['@constant.builtin'] = { fg = colors.const },
    ['@constant.macro'] = { link = 'Macro' },

    -- Strings
    ['@string'] = { link = 'String' },
    ['@string.documentation'] = { fg = colors.string },
    ['@string.regex'] = { fg = colors.warning },
    ['@string.escape'] = { fg = colors.base },
    ['@string.special'] = { fg = colors.base },
    ['@string.special.symbol'] = { fg = colors.const },
    ['@string.special.url'] = { fg = colors.info, underline = true },

    -- Characters & Numbers
    ['@character'] = { link = 'Character' },
    ['@character.special'] = { link = 'SpecialChar' },
    ['@number'] = { link = 'Number' },
    ['@number.float'] = { link = 'Float' },
    ['@boolean'] = { link = 'Boolean' },

    -- Functions (PURE BLACK spotlight — mirrors dark's pure-white-spotlight)
    ['@function'] = { link = 'Function' },
    ['@function.builtin'] = { fg = colors.builtin },
    ['@function.call'] = { fg = colors.func },
    ['@function.macro'] = { link = 'Macro' },
    ['@function.method'] = { fg = colors.func },
    ['@function.method.call'] = { fg = colors.func },

    -- Constructors
    ['@constructor'] = { fg = colors.type },

    -- Keywords
    ['@keyword'] = { link = 'Keyword' },
    ['@keyword.conditional'] = { link = 'Conditional' },
    ['@keyword.repeat'] = { link = 'Repeat' },
    ['@keyword.return'] = { fg = colors.keyword },
    ['@keyword.function'] = { fg = colors.keyword },
    ['@keyword.operator'] = { fg = colors.operator },
    ['@keyword.import'] = { link = 'Include' },
    ['@keyword.exception'] = { link = 'Exception' },
    ['@keyword.directive'] = { link = 'PreProc' },
    ['@keyword.directive.define'] = { link = 'Define' },

    -- Operators
    ['@operator'] = { link = 'Operator' },

    -- Variables
    ['@variable'] = { fg = colors.variable },
    ['@variable.builtin'] = { fg = colors.builtin },
    ['@variable.parameter'] = { fg = colors.parameter },
    ['@variable.parameter.builtin'] = { fg = colors.builtin },
    ['@variable.member'] = { fg = colors.property },

    -- Types
    ['@type'] = { link = 'Type' },
    ['@type.builtin'] = { fg = colors.builtin },
    ['@type.definition'] = { link = 'Typedef' },
    ['@type.qualifier'] = { link = 'Keyword' },

    -- Attributes & Properties
    ['@attribute'] = { fg = colors.base },
    ['@attribute.builtin'] = { fg = colors.builtin },
    ['@property'] = { fg = colors.property },
    ['@field'] = { fg = colors.property },

    -- Modules & Namespaces
    ['@module'] = { fg = colors.namespace },
    ['@module.builtin'] = { fg = colors.builtin },
    ['@label'] = { link = 'Label' },

    -- Punctuation
    ['@punctuation.delimiter'] = { fg = colors.punctuation },
    ['@punctuation.bracket'] = { fg = colors.punctuation },
    ['@punctuation.special'] = { fg = colors.punctuation },

    -- Tags (HTML/XML/JSX)
    ['@tag'] = { fg = colors.tag },
    ['@tag.builtin'] = { fg = colors.builtin },
    ['@tag.attribute'] = { fg = colors.property },
    ['@tag.delimiter'] = { fg = colors.punctuation },

    -- Markup (Markdown, etc.)
    ['@markup.strong'] = { bold = true },
    ['@markup.italic'] = { italic = true },
    ['@markup.strikethrough'] = { strikethrough = true },
    ['@markup.underline'] = { underline = true },

    ['@markup.heading'] = { fg = colors.heading },
    ['@markup.heading.1'] = { fg = colors.heading },
    ['@markup.heading.2'] = { fg = colors.heading },
    ['@markup.heading.3'] = { fg = colors.heading },
    ['@markup.heading.4'] = { fg = colors.heading },
    ['@markup.heading.5'] = { fg = colors.heading },
    ['@markup.heading.6'] = { fg = colors.heading },

    ['@markup.quote'] = { fg = colors.comment },
    ['@markup.math'] = { fg = colors.number },

    ['@markup.link'] = { fg = colors.info, underline = true },
    ['@markup.link.label'] = { fg = colors.string },
    ['@markup.link.url'] = { fg = colors.info, underline = true },

    ['@markup.raw'] = { fg = colors.string },
    ['@markup.raw.block'] = { fg = colors.string },

    ['@markup.list'] = { fg = colors.base },
    ['@markup.list.checked'] = { fg = colors.success },
    ['@markup.list.unchecked'] = { fg = colors.linenr },

    -- Diffs (treesitter)
    ['@diff.plus'] = { fg = colors.diff_add, bold = true },
    ['@diff.minus'] = { fg = colors.diff_delete, italic = true },
    ['@diff.delta'] = { fg = colors.diff_change },

    -- ============================================================================
    -- GIT INTEGRATION (chartreuse + burgundy duo for diffs)
    -- ============================================================================
    DiffAdd = { fg = colors.diff_add, bold = true },
    DiffChange = { fg = colors.diff_change },
    DiffDelete = { fg = colors.diff_delete, italic = true },
    DiffText = { fg = colors.diff_text, bg = colors.bg_alt },

    Added = { fg = colors.diff_add, bold = true },
    Removed = { fg = colors.diff_delete, italic = true },
    Changed = { fg = colors.diff_change },

    -- gitsigns.nvim
    GitSignsAdd = { fg = colors.diff_add },
    GitSignsChange = { fg = colors.diff_change },
    GitSignsDelete = { fg = colors.diff_delete },
    GitSignsAddNr = { fg = colors.diff_add },
    GitSignsChangeNr = { fg = colors.diff_change },
    GitSignsDeleteNr = { fg = colors.diff_delete },
    GitSignsAddLn = { bg = '#dcded5' },     -- chroma-verified (matches delta plus-style)
    GitSignsChangeLn = { bg = '#e8dac0' },  -- warm sepia wash
    GitSignsDeleteLn = { bg = '#edd1d0' },  -- chroma-verified (matches delta minus-style)
    GitSignsCurrentLineBlame = { fg = colors.linenr },

    -- mini.diff
    MiniDiffSignAdd = { fg = colors.diff_add, bold = true },
    MiniDiffSignChange = { fg = colors.diff_change },
    MiniDiffSignDelete = { fg = colors.diff_delete, italic = true },
    MiniDiffOverAdd = { bg = '#dcded5', bold = true },
    MiniDiffOverChange = { bg = '#e8dac0' },
    MiniDiffOverContext = { bg = colors.bg_alt },
    MiniDiffOverDelete = { bg = '#edd1d0', fg = colors.diff_delete, italic = true },

    -- ============================================================================
    -- PLUGIN SUPPORT
    -- ============================================================================

    -- Telescope.nvim (kept for compatibility)
    TelescopeBorder = { fg = colors.base, bg = colors.bg_alt },
    TelescopeNormal = { fg = colors.fg, bg = colors.bg_alt },
    TelescopePromptNormal = { fg = colors.fg, bg = colors.bg_alt },
    TelescopeResultsNormal = { fg = colors.fg, bg = colors.bg_alt },
    TelescopePreviewNormal = { fg = colors.fg, bg = colors.bg_alt },
    TelescopeSelection = { fg = colors.bg, bg = colors.base },
    TelescopeSelectionCaret = { fg = colors.base },
    TelescopeMatching = { fg = colors.warning },
    TelescopePromptPrefix = { fg = colors.base },

    -- Snacks.picker (the actual picker in use)
    SnacksPickerDir = { fg = '#7a3055' },           -- muted vulpes (mirrors dark's #c490a8)
    SnacksPickerPathHidden = { fg = colors.linenr },
    SnacksPickerPathIgnored = { fg = colors.linenr },
    SnacksPickerMatch = { fg = colors.warning },
    SnacksPickerPrompt = { fg = colors.base },
    SnacksPickerSelected = { bg = '#e0d4be' },      -- warm tan selection (matches lazygit)
    SnacksPickerCurrent = { bg = '#ebe2d6' },       -- subtle bg-alt step
    SnacksPickerBorder = { fg = colors.base },
    SnacksPickerTitle = { fg = colors.base, bold = true },

    -- nvim-cmp
    CmpItemAbbrDeprecated = { fg = colors.linenr, strikethrough = true },
    CmpItemAbbrMatch = { fg = colors.base },
    CmpItemAbbrMatchFuzzy = { fg = colors.base },
    CmpItemKindVariable = { fg = colors.variable },
    CmpItemKindInterface = { fg = colors.type },
    CmpItemKindText = { fg = colors.fg },
    CmpItemKindFunction = { fg = colors.func },
    CmpItemKindMethod = { fg = colors.func },
    CmpItemKindKeyword = { fg = colors.keyword },
    CmpItemKindProperty = { fg = colors.variable },
    CmpItemKindUnit = { fg = colors.number },
    CmpItemKindClass = { fg = colors.type },
    CmpItemKindModule = { fg = colors.type },
    CmpItemKindConstant = { fg = colors.const },
    CmpItemKindEnum = { fg = colors.type },
    CmpItemKindStruct = { fg = colors.type },
    CmpItemKindEvent = { fg = colors.base },
    CmpItemKindOperator = { fg = colors.operator },
    CmpItemKindTypeParameter = { fg = colors.type },

    -- Snacks explorer (transparent — uses terminal bg)
    ExplorerNormal = { fg = colors.fg, bg = 'none' },

    -- Which-key
    WhichKey = { fg = colors.base },
    WhichKeyGroup = { fg = colors.keyword },
    WhichKeyDesc = { fg = colors.fg },
    WhichKeySeparator = { fg = colors.linenr },
    WhichKeyFloat = { bg = colors.bg_alt },
    WhichKeyValue = { fg = colors.string },

    -- Indent guides (Snacks.nvim)
    SnacksIndent = { fg = colors.linenr },
    SnacksIndentScope = { fg = colors.linenr },
    SnacksIndent1 = { fg = colors.linenr },
    SnacksIndent2 = { fg = colors.linenr },
    SnacksIndent3 = { fg = colors.linenr },
    SnacksIndent4 = { fg = colors.linenr },
    SnacksIndent5 = { fg = colors.linenr },
    SnacksIndent6 = { fg = colors.linenr },
    SnacksIndent7 = { fg = colors.linenr },
    SnacksIndent8 = { fg = colors.linenr },

    -- Indent Blankline (fallback)
    IblIndent = { fg = colors.linenr },
    IblScope = { fg = colors.linenr },

    -- Dashboard / Alpha
    DashboardHeader = { fg = colors.base },
    DashboardCenter = { fg = colors.keyword },
    DashboardShortcut = { fg = colors.warning },
    DashboardFooter = { fg = colors.linenr },
  }

  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

M.setup()

return M
