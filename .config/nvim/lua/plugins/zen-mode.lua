return {
  "folke/zen-mode.nvim",
  opts = {
    window = {
      backdrop = 0.95,
      width = 120,
      height = 1,
    },
    plugins = {
      twilight = { enabled = true }, -- enable twilight integration
      gitsigns = { enabled = false },
      tmux = { enabled = true },
    },
  },
}
