-- Options: ported from ~/.config/nvim/lua/config/options.lua (WHY comments there)
local o = vim.o

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Clipboard: pbcopy/pbpaste directly, no OSC52
vim.g.clipboard = {
  name = 'macOS-clipboard',
  copy = { ['+'] = 'pbcopy', ['*'] = 'pbcopy' },
  paste = { ['+'] = 'pbpaste', ['*'] = 'pbpaste' },
  cache_enabled = true,
}
o.clipboard = 'unnamedplus'

o.number = true
o.relativenumber = true
o.virtualedit = 'all'
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = true
o.linebreak = true
o.showbreak = '↪ '
o.breakindent = true
o.breakindentopt = 'shift:2'
o.cursorline = true
o.updatetime = 250
o.inccommand = 'split'
o.smoothscroll = false
o.ignorecase = true
o.smartcase = true
o.list = true
o.listchars = 'tab:→ ,trail:·,nbsp:␣,eol:·'
o.undofile = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.splitright = true
o.splitbelow = true
o.mouse = 'a'

o.cmdheight = 0
o.laststatus = 3
o.showmode = false
o.ruler = false
o.showcmd = false
o.signcolumn = 'yes:1'
o.termguicolors = true
o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20'

-- Folding: treesitter via native foldexpr, open by default (replaces nvim-ufo)
o.foldmethod = 'expr'
o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
o.foldlevel = 99
o.foldtext = ''

-- Native 0.12 completion: menu pops up as you type, fed by LSP omnifunc ('o')
-- then buffer words. No blink/nvim-cmp.
o.autocomplete = true
o.complete = 'o,.,w,b'
o.completeopt = 'menuone,noselect,popup,fuzzy'
o.pumheight = 15

o.autoread = true
Config.new_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, '*', function()
  if vim.fn.getcmdwintype() == '' then vim.cmd('checktime') end
end, 'Reload files changed outside nvim (Claude Code edits)')

Config.new_autocmd('ColorScheme', '*', function()
  vim.api.nvim_set_hl(0, 'NonText', { fg = '#262626', ctermfg = 235 })
end, 'Dim listchars')

Config.new_autocmd('TextYankPost', '*', function() vim.hl.on_yank() end, 'Flash yanked text')

-- Colorscheme follows macOS appearance at startup (auto-dark-mode.nvim in
-- 40_plugins keeps it in sync while running).
local dark = vim.fn.system('defaults read -g AppleInterfaceStyle 2>/dev/null'):match('Dark') ~= nil
o.background = dark and 'dark' or 'light'
pcall(vim.cmd.colorscheme, 'vulpes-reddishnovember-' .. o.background)
