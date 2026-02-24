-- ============================================================================
-- THEMING: Colorscheme + auto dark/light + twilight dimming
-- ============================================================================
-- WHY consolidated: These three plugins work together for visual experience.
-- - Custom vulpes colorscheme (warm reds, matches terminal theme)
-- - Auto-switch based on macOS appearance
-- - Twilight dims unfocused code for better focus
-- ============================================================================

return {
  -- ============================================================================
  -- DEFAULT COLORSCHEME
  -- ============================================================================
  -- WHY vulpes: Custom theme that matches Ghostty terminal colors
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vulpes-reddishnovember-dark",
    },
  },

  -- ============================================================================
  -- AUTO DARK/LIGHT MODE
  -- ============================================================================
  -- WHY: macOS switches appearance automatically (sunset, etc.)
  -- This keeps nvim in sync without manual :set background=light
  {
    "f-person/auto-dark-mode.nvim",
    config = function()
      require("auto-dark-mode").setup({
        update_interval = 1000,  -- Check every second
        set_dark_mode = function()
          vim.o.background = "dark"
          vim.cmd("colorscheme vulpes-reddishnovember-dark")
        end,
        set_light_mode = function()
          vim.o.background = "light"
          vim.cmd("colorscheme vulpes-reddishnovember-light")
        end,
      })
      require("auto-dark-mode").init()
    end,
  },

  -- ============================================================================
  -- TWILIGHT: Focus mode for code
  -- ============================================================================
  -- WHY: Dims code outside your current context (function, block, etc.)
  -- Helps focus on what you're editing without hiding surrounding code.
  {
    "folke/twilight.nvim",
    event = "BufReadPost",  -- WHY: Load after file opens, not at startup
    keys = {
      { "<leader>ut", "<cmd>Twilight<cr>", desc = "Toggle Twilight" },
    },
    config = function()
      -- WHY dynamic color: Different dim colors for dark vs light themes
      local function get_twilight_color()
        return vim.o.background == "dark" and "#735865" or "#4a3040"
      end

      local function set_twilight_hl()
        vim.api.nvim_set_hl(0, "Twilight", { fg = get_twilight_color() })
      end

      require("twilight").setup({
        dimming = { alpha = 0.5, inactive = false },
        context = 6,  -- WHY 6: Show ~6 lines of context around cursor
        treesitter = true,  -- WHY: Use treesitter for smart context detection
        expand = { "function", "method", "table", "if_statement" },
      })

      set_twilight_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_twilight_hl })

      -- Twilight is opt-in: use <leader>ut to enable when you want focus mode
    end,
  },
}
