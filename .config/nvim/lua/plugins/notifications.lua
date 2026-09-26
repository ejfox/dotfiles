-- ============================================================================
-- NOTIFICATIONS: snacks.notifier (replaced nvim-notify + noice)
-- WHY: noice was only used to route vim.notify into nvim-notify (cmdline,
-- messages, popupmenu were all disabled). snacks.notifier does that alone,
-- and snacks is already loaded. History: <leader>n (LazyVim default).
-- ============================================================================

return {
  { "rcarriga/nvim-notify", enabled = false },
  { "folke/noice.nvim", enabled = false },

  {
    "folke/snacks.nvim",
    opts = {
      notifier = {
        enabled = true,
        style = "compact",
        timeout = 2500,
        width = { min = 30, max = 0.35 },
        height = { min = 1, max = 5 },
        top_down = false,
        padding = false,
        icons = { error = "", warn = "", info = "", debug = "", trace = "" },
      },
    },
  },
}
