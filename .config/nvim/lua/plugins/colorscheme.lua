return {
  -- Configure Catppuccin theme plugin
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
        integrations = {
          cmp = true,
          gitsigns = true,
          telescope = true,
          treesitter = true,
          notify = true,
          mini = true,
        },
      })

      -- Apply background colors based on which colorscheme loads
      -- Dark mode (mocha): pure black background
      -- Light mode (latte): transparent (inherit terminal bg)
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "catppuccin-mocha",
        callback = function()
          -- Dark mode: pure black backgrounds
          vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
          vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#000000" })
          vim.api.nvim_set_hl(0, "SignColumn", { bg = "#000000" })
          vim.api.nvim_set_hl(0, "LineNr", { bg = "#000000" })
          vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1a1a1a" })
          vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "#1a1a1a" })
        end,
      })

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "catppuccin-latte",
        callback = function()
          -- Light mode: transparent backgrounds (use terminal bg)
          vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
          vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
          vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
          vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
          vim.api.nvim_set_hl(0, "CursorLine", { bg = "none" })
          vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })
        end,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
