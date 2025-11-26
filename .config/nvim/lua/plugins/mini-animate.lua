-- Subtle animations for cursor, window resize, and floating windows
-- No scroll animation (respecting your preference)
return {
  {
    "echasnovski/mini.animate",
    event = "VeryLazy",
    opts = function()
      local animate = require("mini.animate")

      -- Cubic easing feels more natural than linear
      local timing_fast = animate.gen_timing.cubic({ duration = 60, unit = "total" })
      local timing_cursor = animate.gen_timing.cubic({ duration = 80, unit = "total" })

      return {
        -- Cursor path animation - shows trail when jumping
        cursor = {
          enable = true,
          timing = timing_cursor,
          -- Default path works well - shows where cursor traveled
        },

        -- NO scroll animation
        scroll = {
          enable = false,
        },

        -- Window resize animation
        resize = {
          enable = true,
          timing = timing_fast,
        },

        -- Floating window open animation
        open = {
          enable = true,
          timing = timing_fast,
        },

        -- Floating window close animation
        close = {
          enable = true,
          timing = timing_fast,
        },
      }
    end,
  },
}
