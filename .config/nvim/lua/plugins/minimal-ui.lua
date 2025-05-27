return {
  -- Minimal statusline
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "auto",
        component_separators = "",
        section_separators = "",
        globalstatus = true,
      },
      sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          { "filename", path = 0, symbols = { modified = "◆", readonly = "◇", unnamed = "○" } },
        },
        lualine_x = {
          { "diagnostics", symbols = { error = "◆", warn = "◈", info = "◇", hint = "○" } },
        },
        lualine_y = {},
        lualine_z = { { "location", fmt = function(str) return str:gsub(" ", "") end } },
      },
      inactive_sections = {
        lualine_c = { "filename" },
        lualine_x = {},
      },
    },
  },
  
  -- Zen mode for focused writing
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      window = {
        backdrop = 1,
        width = 80,
        height = 1,
        options = {
          signcolumn = "no",
          number = false,
          relativenumber = false,
          cursorline = false,
          cursorcolumn = false,
          foldcolumn = "0",
          list = false,
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
        },
        tmux = { enabled = true },
        gitsigns = { enabled = false },
      },
    },
  },
  
  -- Minimal buffer line
  {
    "akinsho/bufferline.nvim",
    enabled = false, -- Disable bufferline entirely
  },
  
  -- Simplify Neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        width = 30,
        mappings = {
          ["<space>"] = "none",
        },
      },
      default_component_configs = {
        icon = {
          folder_closed = "▸",
          folder_open = "▾",
          folder_empty = "○",
          default = "◇",
        },
        git_status = {
          symbols = {
            added = "◆",
            modified = "◈",
            deleted = "◇",
            renamed = "→",
            untracked = "○",
            ignored = "·",
            unstaged = "□",
            staged = "■",
            conflict = "◊",
          },
        },
      },
    },
  },
}