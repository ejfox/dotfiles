-- ============================================================================
-- GIT: Gutter signs, conflict resolution, oil.nvim git status
-- Consolidates: minimal-git.lua, oil-git-status.lua
-- ============================================================================

return {
  -- Gutter signs for changed lines
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "?" },
      },
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
      current_line_blame = false,
      attach_to_untracked = false,
      sign_priority = 6,
      update_debounce = 100,
      max_file_length = 40000,
      preview_config = { border = "none", style = "minimal" },
    },
  },

  -- Merge conflict resolution
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = function()
      require("git-conflict").setup({
        default_mappings = false,
        default_commands = true,
        disable_diagnostics = false,
        highlights = { incoming = "DiffAdd", current = "DiffText" },
      })
      -- Keybindings: co=ours, ct=theirs, cb=both, c0=none, [x/]x=prev/next
      vim.keymap.set("n", "co", "<Plug>(git-conflict-ours)", { desc = "Choose Ours" })
      vim.keymap.set("n", "ct", "<Plug>(git-conflict-theirs)", { desc = "Choose Theirs" })
      vim.keymap.set("n", "cb", "<Plug>(git-conflict-both)", { desc = "Choose Both" })
      vim.keymap.set("n", "c0", "<Plug>(git-conflict-none)", { desc = "Choose None" })
      vim.keymap.set("n", "[x", "<Plug>(git-conflict-prev-conflict)", { desc = "Prev Conflict" })
      vim.keymap.set("n", "]x", "<Plug>(git-conflict-next-conflict)", { desc = "Next Conflict" })
    end,
  },

  -- Git status icons in oil.nvim file explorer
  {
    "refractalize/oil-git-status.nvim",
    dependencies = { "stevearc/oil.nvim" },
    opts = {
      symbols = {
        index = {
          ["!"] = "◌", ["?"] = "?", ["A"] = "+", ["C"] = "+",
          ["D"] = "✗", ["M"] = "+", ["R"] = "→", ["T"] = "+", ["U"] = "‼",
        },
        working_tree = {
          ["!"] = "◌", ["?"] = "?", ["A"] = "+", ["C"] = "C",
          ["D"] = "✗", ["M"] = "!", ["R"] = "→", ["T"] = "T", ["U"] = "‼",
        },
      },
    },
  },
}
