return {
  "f-person/auto-dark-mode.nvim",
  config = function()
    local auto_dark_mode = require("auto-dark-mode")
    auto_dark_mode.setup({
      update_interval = 1000,
      set_dark_mode = function()
        vim.o.background = "dark"
        vim.cmd("colorscheme vulpes_reddish_dark")
      end,
      set_light_mode = function()
        vim.o.background = "light"
        vim.cmd("colorscheme vulpes_reddish_light")
      end,
    })
    auto_dark_mode.init()
  end,
}

