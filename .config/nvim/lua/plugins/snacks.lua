return {
  {
    "folke/snacks.nvim",
    opts = {
      -- Disable smooth scrolling (you have vim.opt.smoothscroll = false already)
      scroll = { enabled = false },

      -- Dashboard on startup
      dashboard = {
        width = 60,
        preset = {
          header = [[
 _______  _______  __   __
|       ||       ||  |_|  |
|    ___||   _   ||       |
|   |___ |  | |  ||       |
|    ___||  |_|  | |     |
|   |    |       ||   _   |
|___|    |_______||__| |__|
          ]],
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
        },
      },
    },
  },
}
