return {
  -- Add svelte to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "svelte" })
      end
    end,
  },

  -- Configure svelte LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        svelte = {
          keys = {
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
          },
          capabilities = {
            workspace = {
              didChangeWatchedFiles = vim.fn.has("nvim-0.10") == 0 and { dynamicRegistration = true },
            },
          },
        },
      },
    },
  },

  -- Ensure svelte-language-server is installed
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "svelte-language-server" })
    end,
  },

  -- Add svelte to formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        svelte = { "prettier" },
      },
    },
  },
}
