return {
  -- Ensure proper Vue LSP setup with proper TypeScript integration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Vue Language Server (Volar)
        volar = {
          filetypes = { "vue" },
          init_options = {
            vue = {
              hybridMode = false, -- Use Volar's own TypeScript service
            },
          },
        },
        -- TypeScript language server with Vue plugin
        tsserver = {
          filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
          init_options = {
            plugins = {
              {
                name = "@vue/typescript-plugin",
                location = vim.fn.expand("~/.local/share/nvim/mason/packages/vue-language-server/node_modules/@vue/language-server"),
                languages = { "vue" },
              },
            },
          },
        },
      },
      setup = {
        volar = function(_, opts)
          -- Additional Volar-specific setup
          opts.on_attach = function(client, bufnr)
            -- Enable formatting
            client.server_capabilities.documentFormattingProvider = true
            client.server_capabilities.documentRangeFormattingProvider = true
          end
        end,
      },
    },
  },

  -- Mason - ensure Vue LSP servers are installed
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "vue-language-server", -- Volar
        "typescript-language-server",
        "eslint-lsp",
        "prettier",
      })
    end,
  },

  -- Better TypeScript errors
  {
    "dmmulroy/ts-error-translator.nvim",
    ft = { "typescript", "typescriptreact", "vue" },
    config = true,
  },
}