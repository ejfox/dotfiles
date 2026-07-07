-- ============================================================================
-- STRUDEL: Live code music from Neovim via strudel.cc
-- Syncs buffer ↔ browser, controls playback, evals code
-- File types: .str, .std → detected as javascript for treesitter highlighting
-- Note: lazy=false because setup() registers the filetype autocmd (see gh#5)
-- ============================================================================

return {
  "gruvw/strudel.nvim",
  build = "npm ci",
  lazy = false,
  opts = {},
  keys = {
    { "<leader>sl", "<cmd>StrudelLaunch<cr>", desc = "Strudel Launch" },
    { "<leader>st", "<cmd>StrudelToggle<cr>", desc = "Strudel Toggle play/stop" },
    { "<leader>su", "<cmd>StrudelUpdate<cr>", desc = "Strudel Update (eval)" },
    { "<leader>sq", "<cmd>StrudelQuit<cr>", desc = "Strudel Quit" },
  },
}
