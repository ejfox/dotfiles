-- ============================================================================
-- THEMING: Colorscheme + auto dark/light + snacks.dim focus
-- ============================================================================
-- WHY consolidated: These three plugins work together for visual experience.
-- - Custom vulpes colorscheme (warm reds, matches terminal theme)
-- - Auto-switch based on macOS appearance
-- - snacks.dim dims unfocused code for better focus
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
  -- DIM: Focus mode for code (snacks.dim, replaced twilight.nvim)
  -- ============================================================================
  -- WHY: Dims code outside your current scope (function, block, etc.)
  -- Helps focus on what you're editing without hiding surrounding code.
  -- Opt-in via <leader>ut; also auto-enabled inside zen/prose mode.
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>ut", function() Snacks.toggle.dim():toggle() end, desc = "Toggle Dim (focus)" },
    },
    init = function()
      -- WHY dynamic color: Different dim colors for dark vs light themes
      local function set_dim_hl()
        local fg = vim.o.background == "dark" and "#735865" or "#4a3040"
        vim.api.nvim_set_hl(0, "SnacksDim", { fg = fg })
      end
      set_dim_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_dim_hl })
    end,
  },
}
