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

      -- Keybindings for merge conflicts
      vim.keymap.set("n", "co", "<Plug>(git-conflict-ours)", { desc = "Choose Ours (current)" })
      vim.keymap.set("n", "ct", "<Plug>(git-conflict-theirs)", { desc = "Choose Theirs (incoming)" })
      vim.keymap.set("n", "cb", "<Plug>(git-conflict-both)", { desc = "Choose Both" })
      vim.keymap.set("n", "c0", "<Plug>(git-conflict-none)", { desc = "Choose None" })
      vim.keymap.set("n", "[x", "<Plug>(git-conflict-prev-conflict)", { desc = "Previous Conflict" })
      vim.keymap.set("n", "]x", "<Plug>(git-conflict-next-conflict)", { desc = "Next Conflict" })
    end,
  },

  -- Minimal diff view (disabled: using claude-code-workflow.lua config instead)
  {
    "sindrets/diffview.nvim",
    enabled = false,
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