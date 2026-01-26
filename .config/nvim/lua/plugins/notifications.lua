-- ============================================================================
-- NOTIFICATIONS: nvim-notify styling + noice integration
-- Consolidates: notify.lua, noice.lua
-- ============================================================================

return {
  -- Notification styling
  {
    "rcarriga/nvim-notify",
    config = function()
      local notify = require("notify")
      notify.setup({
        max_width = function() return math.floor(vim.o.columns * 0.35) end,
        max_height = 5,
        minimum_width = 30,
        stages = "fade",
        timeout = 2500,
        background_colour = "#000000",
        render = "compact",
        icons = { ERROR = "", WARN = "", INFO = "", DEBUG = "" },
        top_down = false,
        padding = false,
      })
      vim.notify = notify
    end,
  },

  -- Noice: route notifications through nvim-notify
  {
    "folke/noice.nvim",
    opts = {
      cmdline = { enabled = false },
      messages = { enabled = false },
      popupmenu = { enabled = false },
      notify = { enabled = true, view = "notify" },
      views = {
        notify = {
          backend = "notify",
          render = "wrapped-compact",
        },
      },
    },
  },
}
