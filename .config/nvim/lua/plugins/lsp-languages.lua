-- ============================================================================
-- LSP-LANGUAGES: servers LazyVim has no (or too heavy an) extra for
-- ============================================================================
-- JSON/YAML/Python/Docker/TOML/Tailwind come from LazyVim extras (lazyvim.json).
-- Markdown gets marksman only: the lang.markdown extra also turns on
-- render-markdown + markdownlint, which restyles and lints the vault.

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = { filetypes = { "sh", "bash", "zsh" } },
        cssls = {},
        html = {},
        marksman = {},
        glsl_analyzer = {},
        rust_analyzer = {},
        -- Ships with Xcode, not mason. Swift/ObjC only: clangd owns C/C++.
        sourcekit = {
          mason = false,
          cmd = { "xcrun", "sourcekit-lsp" },
          filetypes = { "swift", "objc", "objcpp" },
        },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash-language-server",
        "shellcheck",
        "css-lsp",
        "html-lsp",
        "marksman",
        "glsl_analyzer",
        "rust-analyzer",
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "scss", "swift", "glsl", "sql", "rust" })
      end
    end,
  },
}
