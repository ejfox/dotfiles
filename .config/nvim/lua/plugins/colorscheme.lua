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
        custom_highlights = function(colors)
          -- Only override backgrounds in dark mode (mocha)
          -- Light mode (latte) uses default catppuccin colors for better contrast
          local highlights = {}

          if vim.o.background == "dark" then
            highlights = {
              -- Pure black editor background in dark mode
              Normal = { bg = "#000000" },
              NormalFloat = { bg = "#000000" },
              FloatBorder = { bg = "#000000" },
              SignColumn = { bg = "#000000" },
              LineNr = { bg = "#000000" },
              CursorLine = { bg = "#1a1a1a" },
              CursorLineNr = { bg = "#1a1a1a" },
            }
          end

          return highlights
        end,
        integrations = {
          cmp = true,
          gitsigns = true,
          telescope = true,
          treesitter = true,
          notify = true,
          mini = true,
        },
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
