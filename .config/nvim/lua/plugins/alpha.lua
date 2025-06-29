return {
  {
    "folke/snacks.nvim",
    opts = {
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
          -- {
          --   pane = 2,
          --   icon = "◆",
          --   title = "Today's Mission",
          --   section = "terminal",
          --   cmd = "command -v things-cli >/dev/null && things-cli today | head -n 3 | cut -d'|' -f1 | sed 's/^/  ◆ /' || echo '  ◆ No tasks configured'",
          --   height = 4,
          --   padding = 1,
          --   ttl = 10 * 60,
          --   indent = 2,
          -- },
          -- {
          --   pane = 2,
          --   icon = "▪",
          --   title = "AI Insights",
          --   section = "terminal",
          --   cmd = "if [ -f /tmp/startup_cache/reflection_cache.txt ]; then head -n 3 /tmp/startup_cache/reflection_cache.txt | sed 's/^/  ▪ /'; else echo '  ▪ Run ~/.startup.sh for insights'; fi",
          --   height = 4,
          --   padding = 1,
          --   ttl = 20 * 60,
          --   indent = 2,
          -- },
        },
      },
    },
  },
}