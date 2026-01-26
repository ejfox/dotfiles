-- ============================================================================
-- NEOVIM OPTIONS
-- ============================================================================
-- These settings override LazyVim defaults. Most are about creating a
-- minimal, distraction-free editing experience with smart defaults.
--
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- ============================================================================
-- CLIPBOARD
-- ============================================================================
-- WHY pbcopy instead of OSC52: OSC52 causes clipboard spam on refocus in
-- tmux/ghostty. Using native macOS clipboard is more reliable and instant.

vim.g.clipboard = {
  name = 'macOS-clipboard',
  copy = {
    ['+'] = 'pbcopy',
    ['*'] = 'pbcopy',
  },
  paste = {
    ['+'] = 'pbpaste',
    ['*'] = 'pbpaste',
  },
  cache_enabled = true,
}
vim.g.clipboard_osc52 = false      -- Disable OSC52 (neovim 0.11+ feature)
vim.opt.clipboard = 'unnamedplus'  -- Sync vim register with system clipboard

-- ============================================================================
-- LINE NUMBERS
-- ============================================================================
-- WHY hybrid numbers: Relative numbers for quick j/k jumps (5j, 12k),
-- but absolute every 10 lines for orientation in large files.

vim.opt.number = true
vim.opt.relativenumber = true

-- Make absolute "landmark" numbers stand out (white, not dim)
vim.api.nvim_set_hl(0, "LineNrAbsolute", { fg = "#ffffff" })
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    if vim.o.background == "dark" then
      vim.api.nvim_set_hl(0, "LineNrAbsolute", { fg = "#ffffff" })
    else
      vim.api.nvim_set_hl(0, "LineNrAbsolute", { fg = "#000000" })
    end
  end,
})

-- Custom statuscolumn: absolute every 10 lines, relative otherwise
vim.opt.statuscolumn = "%!v:lua.StatusColumn()"

_G.StatusColumn = function()
  local lnum = vim.v.lnum
  local cur = vim.fn.line(".")

  -- Current line: white, absolute
  if lnum == cur then
    return "%#LineNrAbsolute#%=" .. lnum .. " "
  end

  -- Every 10th line: white, absolute (landmarks for orientation)
  if lnum % 10 == 0 then
    return "%#LineNrAbsolute#%=" .. lnum .. " "
  end

  -- Everything else: dim relative (for quick jumps)
  return "%#LineNr#%=%{v:relnum} "
end

-- ============================================================================
-- EDITING BEHAVIOR
-- ============================================================================

vim.opt.virtualedit = "all"      -- WHY: Move cursor anywhere, even past EOL (useful for column editing)
vim.opt.scrolloff = 8            -- WHY: Keep cursor 8 lines from edge (always see context)
vim.opt.sidescrolloff = 8
vim.opt.wrap = true              -- WHY: Wrapped lines are easier to read than horizontal scrolling
vim.opt.cursorline = true        -- WHY: Highlight current line for visual orientation
vim.opt.updatetime = 250         -- WHY: Faster CursorHold events (better for plugins)
vim.opt.inccommand = "split"     -- WHY: Live preview of :s/foo/bar substitutions
vim.opt.smoothscroll = false     -- WHY: Instant scrolling feels snappier

-- Case insensitive search UNLESS you type a capital letter
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ============================================================================
-- INVISIBLE CHARACTERS
-- ============================================================================
-- WHY show them: Catch trailing whitespace and mixed tabs/spaces.
-- WHY subtle: They shouldn't distract from actual code.

vim.opt.list = true
vim.opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣", eol = "·" }

-- Make end-of-line markers nearly invisible
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "NonText", { fg = "#262626", ctermfg = 235 })
  end,
})

-- ============================================================================
-- MINIMAL UI
-- ============================================================================
-- WHY hide everything: Screen space is precious. Statusline shows what you need.

vim.opt.cmdheight = 0            -- Hide command line unless typing
vim.opt.laststatus = 3           -- Global statusline (not per-window)
vim.opt.showmode = false         -- Mode shown in statusline, not below it
vim.opt.ruler = false            -- Position shown in statusline
vim.opt.showcmd = false          -- Don't show partial commands
vim.opt.signcolumn = "yes:1"     -- Always show, 1 char wide (no layout shift)

-- Simple statusline: filename [modified]           line:col
vim.opt.statusline = "%f %m%=%l:%c"

-- ============================================================================
-- WRAPPING & INDENTATION
-- ============================================================================

vim.opt.showbreak = "↪ "         -- Visual indicator for wrapped lines
vim.opt.breakindent = true       -- Wrapped lines match original indent
vim.opt.breakindentopt = "shift:2"

-- ============================================================================
-- COLORS & FONTS
-- ============================================================================

vim.opt.termguicolors = true     -- WHY: 24-bit color support
vim.opt.guifont = "Monaspace Krypton:h13"

-- Neovide-specific (GUI nvim)
vim.g.neovide_theme = "auto"
vim.g.neovide_floating_shadow = false

-- Make UI elements transparent in light mode (matches Ghostty transparency)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = { "catppuccin-latte" },
  callback = function()
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLineSel", { bg = "none" })
  end,
})

-- ============================================================================
-- AUTO-RELOAD
-- ============================================================================
-- WHY: When you edit a file externally (or git checkout), nvim picks it up
-- automatically. No more "file changed on disk" prompts.

vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- ============================================================================
-- FOLDING
-- ============================================================================
-- Handled by nvim-ufo plugin (see plugins/nvim-ufo.lua)
