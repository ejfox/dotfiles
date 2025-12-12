return {
  "rcarriga/nvim-notify",
  config = function()
    local notify = require("notify")

    notify.setup({
      -- Notification window sizing - FULL KHABIB MODE
      -- 50% of screen width, 10 lines tall - wisdom deserves space
      max_width = function()
        return math.floor(vim.o.columns * 0.5)
      end,
      max_height = 10,
      minimum_width = 50,        -- Never too small to read

      -- Animation and appearance
      stages = "fade_in_slide_out",
      timeout = 3500,
      background_colour = "#1a1a1a",

      -- Icons for different notification levels
      icons = {
        ERROR = "󰅙",              -- Hardtime says you messed up
        WARN = "󰔨",               -- Building awareness
        INFO = "󰋼",               -- Coach Khabib speaking
        DEBUG = "󰔍",              -- Finding the target
      },

      -- Position: top-right (doesn't interfere with editor)
      top_down = true,

      -- Highlight groups (customize colors if needed)
      highlight = "NotifyBackground",
    })

    vim.notify = notify
  end,
}
