return {
  -- Vulpes-reddish colorscheme (local implementation)
  {
    "folke/lazy.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- Load vulpes-reddish with auto-dark-mode support
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          -- Load appropriate colorscheme based on background
          local bg = vim.o.background
          if bg == "dark" then
            require("colors.vulpes_reddish_dark")
          else
            require("colors.vulpes_reddish_light")
          end
        end,
      })

      -- Watch for background changes (auto-dark-mode)
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        callback = function()
          local bg = vim.o.background
          if bg == "dark" then
            require("colors.vulpes_reddish_dark")
          else
            require("colors.vulpes_reddish_light")
          end
        end,
      })

      -- Apply initial colorscheme
      local bg = vim.o.background
      if bg == "dark" then
        require("colors.vulpes_reddish_dark")
      else
        require("colors.vulpes_reddish_light")
      end
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vulpes_reddish_dark",
    },
  },
}
