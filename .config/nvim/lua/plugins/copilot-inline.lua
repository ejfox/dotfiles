-- Copilot with INLINE ghost text (cursor-style, old-school)
return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      -- INLINE GHOST TEXT (what you want!)
      suggestion = {
        enabled = true,                -- ENABLE inline suggestions
        auto_trigger = true,           -- Show as you type
        hide_during_completion = true,
        debounce = 75,                 -- Fast response (75ms)
        keymap = {
          accept = "<Tab>",            -- Tab to accept (your comfort zone)
          accept_word = "<C-Right>",   -- Accept one word
          accept_line = "<C-l>",       -- Accept one line
          next = "]s",                 -- ]s = next suggestion (matches ]x, ]c pattern)
          prev = "[s",                 -- [s = prev suggestion
          dismiss = "<C-]>",           -- Ctrl+] dismiss
        },
      },

      -- Panel for browsing multiple suggestions
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",             -- Alt+Enter opens panel
        },
        layout = {
          position = "right",          -- Right side panel
          ratio = 0.4,
        },
      },

      -- Filetypes
      filetypes = {
        markdown = true,
        help = true,
        gitcommit = true,
        yaml = true,
        ["*"] = true,                  -- Enable for all file types
      },
    },
  },
}
