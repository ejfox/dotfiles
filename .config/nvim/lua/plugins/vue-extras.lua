return {
  -- Better Vue syntax highlighting and indentation
  {
    "posva/vim-vue",
    ft = "vue",
  },

  -- Vue 3 snippets
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      -- Load Vue-specific snippets
      require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./snippets/vue" } })
    end,
  },

  -- Auto-close tags in Vue templates
  {
    "windwp/nvim-ts-autotag",
    ft = { "vue", "html", "javascript", "typescript", "javascriptreact", "typescriptreact" },
    config = true,
  },

  -- Better Vue component navigation
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fv",
        function()
          require("telescope.builtin").find_files({
            find_command = { "rg", "--files", "--glob", "*.vue" },
          })
        end,
        desc = "Find Vue files",
      },
    },
  },

  -- Vue devtools integration (optional)
  {
    "webtools-vue/vue-devtools.nvim",
    ft = "vue",
    build = "npm install && npm run build",
    config = function()
      require("vue-devtools").setup({
        -- Config options
      })
    end,
    enabled = false, -- Enable this if you want Vue devtools integration
  },

  -- Emmet support for Vue templates
  {
    "mattn/emmet-vim",
    ft = { "vue", "html", "css", "scss", "javascript", "typescript" },
    config = function()
      vim.g.user_emmet_settings = {
        javascript = {
          extends = "jsx",
        },
        vue = {
          extends = "html",
        },
      }
    end,
  },
}