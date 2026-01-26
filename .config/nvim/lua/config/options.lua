-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable OSC 52 clipboard entirely (avoids spam on refocus in tmux/ghostty)
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
-- Explicitly disable OSC 52 (neovim 0.11+ feature)
vim.g.clipboard_osc52 = false

-- Sync default register with system clipboard (via pbcopy, no lag)
vim.opt.clipboard = 'unnamedplus'

vim.g.neovide_theme = "auto"
vim.g.neovide_floating_shadow = false -- Cleaner floating windows
-- hybrid line numbers with periodic absolute references
vim.opt.number = true
vim.opt.relativenumber = true

-- Highlight for absolute landmark numbers (white, not dim)
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

  -- Every 10th line: white, absolute
  if lnum % 10 == 0 then
    return "%#LineNrAbsolute#%=" .. lnum .. " "
  end

  -- Everything else: dim relative
  return "%#LineNr#%=%{v:relnum} "
end

-- disable smooth scrolling
vim.opt.smoothscroll = false

-- Folding handled by nvim-ufo plugin (see plugins/nvim-ufo.lua)

-- make it so space-e only toggles the explorer if its active
-- vim.keymap.set("n", "<space>e", function()
--   if vim.fn.win_gettype() == "popup" then
--     return "<space>e"
--   end
--   return "<cmd>Neotree toggle<cr>"
-- end, { noremap = true, expr = true })

-- set column mode for navigation
vim.opt.virtualedit = "all"

-- keep cursor within 8 lines of top/bottom edge
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- wrap lines by default
vim.opt.wrap = true

-- highlight current line
vim.opt.cursorline = true

-- faster CursorHold (better for hotreload + general responsiveness)
vim.opt.updatetime = 250

-- Preview substitutions live as you type
vim.opt.inccommand = "split"

-- Case insensitive unless you type a capital letter
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Display invisible chars (optional, but nice if you tweak it)
vim.opt.list = true
-- eol = "·" is a subtle dot, or use "" to hide entirely
vim.opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣", eol = "·" }

-- Make end-of-line character extremely subtle (barely visible)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Nearly invisible eol/newline markers
    vim.api.nvim_set_hl(0, "NonText", { fg = "#262626", ctermfg = 235 }) -- very dark gray
  end,
})

-- Minimal UI settings
vim.opt.cmdheight = 0 -- Hide command line unless typing
vim.opt.laststatus = 3 -- Global statusline
vim.opt.showmode = false -- Don't show mode (statusline handles it)
vim.opt.ruler = false -- Don't show cursor position
vim.opt.showcmd = false -- Don't show command in bottom bar

-- Minimalist statusline: filename [+]           line:col
vim.opt.statusline = "%f %m%=%l:%c"

-- Minimal signcolumn
vim.opt.signcolumn = "yes:1" -- Always show, but only 1 char wide

-- Font to match your terminal
vim.opt.guifont = "Monaspace Krypton:h13"
-- clipboard configured via vim.g.clipboard at top of file
vim.opt.showbreak = "↪ " -- What wrapped lines show
vim.opt.breakindent = true -- Wrapped lines match indent
vim.opt.breakindentopt = "shift:2" -- But shifted a bit

-- True color support for terminal
vim.opt.termguicolors = true


-- Make UI elements (statusline, tabline) transparent in light mode
-- Editor backgrounds are handled by colorscheme.lua
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

-- Auto-reload files when changed externally (if buffer not modified locally)
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})
