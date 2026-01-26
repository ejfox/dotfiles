-- ============================================================================
-- TAILWIND: Tailwind CSS utilities
-- ============================================================================

return {
  -- Fold/conceal long Tailwind class strings, reveal on cursor line
  {
    "razak17/tailwind-fold.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "html", "svelte", "astro", "vue", "typescriptreact", "javascriptreact", "php", "blade" },
    opts = {
      min_count = 2, -- minimum number of classes before folding
      symbol = "...", -- symbol shown when folded
    },
  },
}
