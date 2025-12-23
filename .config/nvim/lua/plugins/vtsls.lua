return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      vtsls = {
        cmd = { vim.fn.expand("~/.local/bin/vtsls-wrapper"), "--stdio" },
      },
    },
  },
}
