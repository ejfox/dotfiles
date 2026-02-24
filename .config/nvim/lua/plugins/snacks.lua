return {
  {
    "folke/snacks.nvim",
    opts = {
      -- Statuscolumn: separates git and diagnostic signs into own columns
      -- so you never lose info when both appear on the same line
      statuscolumn = {
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = {
          open = false,   -- don't show icon on open folds (minimal)
          git_hl = false, -- don't color fold icons by git status
        },
      },

      -- Disable smooth scrolling (you have vim.opt.smoothscroll = false already)
      scroll = { enabled = false },

      -- File explorer configuration
      picker = {
        sources = {
          explorer = {
            win = {
              list = {
                wo = {
                  winhighlight = "Normal:ExplorerNormal,NormalNC:ExplorerNormal,EndOfBuffer:ExplorerNormal,SignColumn:ExplorerNormal",
                },
              },
            },
          },
          -- Git diff: bottom layout, tall preview (75%)
          git_diff = {
            layout = {
              preset = "bottom",
              layout = { height = 0.75 },
            },
          },
          -- Git status: ivy style (horizontal at bottom)
          git_status = {
            layout = {
              preset = "ivy",
            },
          },
        },
      },

      -- Dashboard on startup
      dashboard = {
        width = 80,
        preset = {
          header = [[
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                              ┃
┃                          ████████████▇▃▃                                     ┃
┃                          ▛█████████████████▃▃                                ┃
┃                         ▕  ████████████████████▃▃                            ┃
┃                             ▜█████████████████████                           ┃
┃                              ▝▜▒▉███████████████████▄▄                       ┃
┃                                  ▜▉████████████████████▃                     ┃
┃                                    ▔▔▜██████████████████▃                    ┃
┃                                        ▂██████████████████▃                  ┃
┃                                      ▂▒████████████████████▃                 ┃
┃                                  ▅██████████████████████████▃                ┃
┃                                  ████████████████████████████▃               ┃
┃                                   ████████████████████████████               ┃
┃                                    ▜██████████████████████████▒              ┃
┃                                      ▔░▒███████████████████████              ┃
┃                                          ░▒████████████████████▒             ┃
┃                     ░                      ▔ ███████████████████             ┃
┃                     █░                       ▔ █████████████████             ┃
┃                    ▓██▓▓ ░▓▓▒░                 ▔ ███████████████▒            ┃
┃                     ██████████▒▒                 ▔███████████████            ┃
┃                     █████████████▒                ▔█████████████▒            ┃
┃                     ██████████████▒                ▔████████████             ┃
┃                     ▓██████████████▒                ▒███████████             ┃
┃                      ███████████████                ▒██████████▒             ┃
┃                       ██████████████                ▒█████████▒              ┃
┃                        █████████████                ▒█████████               ┃
┃                         ████████████                ▒████████                ┃
┃                          ▒█████████▒                ████████                 ┃
┃                            ████████                 ███████                  ┃
┃                             ▒█████   ░            ▒███████                   ┃
┃                                ██   ░            ███████░                    ┃
┃                                    █           ▒██████░                      ┃
┃                                  ░█         ▒███████░                        ┃
┃                                 ░     ░▒▓█████████░                          ┃
┃                             ░░▓███████████████░                              ┃
┃                       ░░░░▓██████████████░                                   ┃
┃                                █████                                         ┃
┃                                                                              ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
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
