return {
  -- Minimal git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      -- Only show in signcolumn, no virtual text
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
      current_line_blame = false,
      -- No popups or virtual text
      attach_to_untracked = false,
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil,
      max_file_length = 40000,
      preview_config = {
        border = "none",
        style = "minimal",
      },
    },
  },

  -- Simplify git conflict markers
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = function()
      require("git-conflict").setup({
        default_mappings = false,
        default_commands = true,
        disable_diagnostics = false,
        highlights = {
          incoming = "DiffAdd",
          current = "DiffText",
        },
      })
    end,
  },

  -- Minimal diff view
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
    opts = {
      enhanced_diff_hl = false,
      use_icons = false,
      signs = {
        fold_closed = "▸",
        fold_open = "▾",
      },
    },
  },
}