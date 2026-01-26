-- ============================================================================
-- THEMING: Colorscheme, auto dark/light mode, twilight dimming
-- Consolidates: colorscheme.lua, auto-dark-mode.lua, twilight.lua
-- ============================================================================

return {
  -- Default colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vulpes-reddishnovember-dark",
    },
  },

  -- Auto switch dark/light based on system
  {
    "f-person/auto-dark-mode.nvim",
    config = function()
      require("auto-dark-mode").setup({
        update_interval = 1000,
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

  -- Twilight: dim inactive code
  {
    "folke/twilight.nvim",
    event = "BufReadPost",
    keys = {
      { "<leader>ut", "<cmd>Twilight<cr>", desc = "Toggle Twilight" },
    },
    config = function()
      local function get_twilight_color()
        return vim.o.background == "dark" and "#735865" or "#4a3040"
      end

      local function set_twilight_hl()
        vim.api.nvim_set_hl(0, "Twilight", { fg = get_twilight_color() })
      end

      require("twilight").setup({
        dimming = { alpha = 0.5, inactive = false },
        context = 6,
        treesitter = true,
        expand = { "function", "method", "table", "if_statement" },
      })

      set_twilight_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_twilight_hl })

      -- Enable by default
      vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function()
          vim.defer_fn(function()
            if vim.bo.filetype ~= "" and vim.bo.filetype ~= "dashboard" then
              require("twilight").enable()
            end
          end, 100)
        end,
      })
    end,
  },
}
