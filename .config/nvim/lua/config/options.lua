-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.neovide_theme = "auto"
vim.g.neovide_floating_shadow = false -- Cleaner floating windows
-- disable relative numbers
vim.opt.relativenumber = false

-- disable smooth scrolling
vim.opt.smoothscroll = false

-- make it so space-e only toggles the explorer if its active
-- vim.keymap.set("n", "<space>e", function()
--   if vim.fn.win_gettype() == "popup" then
--     return "<space>e"
--   end
--   return "<cmd>Neotree toggle<cr>"
-- end, { noremap = true, expr = true })

-- set column mode for navigation
vim.opt.virtualedit = "all"

-- keep cursor in the center
-- vim.opt.scrolloff = 8

-- Preview substitutions live as you type
vim.opt.inccommand = "split"

-- Case insensitive unless you type a capital letter
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Display invisible chars (optional, but nice if you tweak it)
vim.opt.list = true
vim.opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }

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
vim.opt.clipboard = ""
vim.opt.showbreak = "↪ " -- What wrapped lines show
vim.opt.breakindent = true -- Wrapped lines match indent
vim.opt.breakindentopt = "shift:2" -- But shifted a bit

-- Make background transparent in light mode only
vim.opt.termguicolors = true
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = { "ayu-light", "catppuccin-latte" },
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
    vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLineSel", { bg = "none" })
  end,
})
