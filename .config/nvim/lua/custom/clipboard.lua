-- OSC52 clipboard sync (works over SSH + tmux)
-- Yanking with "+y or "*y copies to system clipboard via terminal escape sequence

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

-- Override the empty clipboard setting from options.lua
vim.opt.clipboard = 'unnamedplus'
