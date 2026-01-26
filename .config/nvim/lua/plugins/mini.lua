-- ============================================================================
-- MINI.NVIM: Lightweight utilities (animate, diff)
-- Consolidates: mini-animate.lua, mini-diff.lua
-- ============================================================================

return {
  -- Subtle animations for cursor and windows
  {
    "echasnovski/mini.animate",
    event = "VeryLazy",
    opts = function()
      local animate = require("mini.animate")
      local timing_fast = animate.gen_timing.cubic({ duration = 60, unit = "total" })
      local timing_cursor = animate.gen_timing.cubic({ duration = 80, unit = "total" })

      return {
        cursor = { enable = true, timing = timing_cursor },
        scroll = { enable = false }, -- Disabled
        resize = { enable = true, timing = timing_fast },
        open = { enable = true, timing = timing_fast },
        close = { enable = true, timing = timing_fast },
      }
    end,
  },

  -- Inline diff visualization
  {
    "echasnovski/mini.diff",
    event = "VeryLazy",
    opts = {
      view = {
        style = "sign",
        signs = { add = "▎", change = "▎", delete = "" },
        priority = 199,
      },
      delay = { text_change = 200 },
      mappings = {
        apply = "gh",
        reset = "gH",
        textobject = "gh",
        goto_first = "[H",
        goto_prev = "[h",
        goto_next = "]h",
        goto_last = "]H",
      },
    },
    keys = {
      { "<leader>go", function() require("mini.diff").toggle_overlay() end, desc = "Toggle diff overlay" },
    },
    config = function(_, opts)
      require("mini.diff").setup(opts)
      vim.defer_fn(function() pcall(require("mini.diff").toggle_overlay) end, 100)
    end,
  },
}
