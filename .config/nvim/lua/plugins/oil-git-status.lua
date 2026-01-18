-- Git status icons in oil.nvim
return {
  {
    "refractalize/oil-git-status.nvim",
    dependencies = { "stevearc/oil.nvim" },
    opts = {
      -- Symbols match p10k: ? = untracked, ! = unstaged, + = staged
      symbols = {
        index = {
          -- Index = staged area (ready to commit)
          ["!"] = "◌",  -- ignored
          ["?"] = "?",  -- untracked
          ["A"] = "+",  -- added (staged)
          ["C"] = "+",  -- copied (staged)
          ["D"] = "✗",  -- deleted (staged)
          ["M"] = "+",  -- modified (staged) - matches p10k staged
          ["R"] = "→",  -- renamed (staged)
          ["T"] = "+",  -- type changed (staged)
          ["U"] = "‼",  -- unmerged (conflict)
        },
        working_tree = {
          -- Working tree = unstaged changes
          ["!"] = "◌",  -- ignored
          ["?"] = "?",  -- untracked - matches p10k
          ["A"] = "+",  -- added
          ["C"] = "C",  -- copied
          ["D"] = "✗",  -- deleted
          ["M"] = "!",  -- modified (unstaged) - matches p10k unstaged
          ["R"] = "→",  -- renamed
          ["T"] = "T",  -- type changed
          ["U"] = "‼",  -- unmerged (conflict)
        },
      },
    },
  },
}
