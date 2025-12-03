return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      -- Inline ghost text suggestions
      suggestion = {
        enabled = not vim.g.ai_cmp,
        auto_trigger = false,        -- Tab-completion style (not auto-popup)
        hide_during_completion = vim.g.ai_cmp,
        debounce = 150,              -- Wait 150ms before showing
        trigger_on_accept = true,    -- Show next suggestion after accepting
        keymap = {
          accept = false,            -- Handled by nvim-cmp (Tab/Enter)
          next = "<M-]>",            -- Alt+] for next
          prev = "<M-[>",            -- Alt+[ for prev
          dismiss = "<C-]>",         -- Ctrl+] to dismiss
        },
      },

      -- Panel: split window with multiple suggestions
      panel = {
        enabled = true,              -- Enable `:Copilot panel` command
        auto_refresh = true,         -- Refresh as you type
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
        layout = {
          position = "bottom",
          ratio = 0.4,
        },
      },

      -- File types where Copilot is enabled
      filetypes = {
        markdown = true,
        help = true,
      },

      -- Model behavior tuning
      server_opts_overrides = {
        settings = {
          advanced = {
            temperature = 0,         -- Deterministic (reliable completions)
            listCount = 3,           -- Max 3 suggestions in panel
            inlineSuggestCount = 2,  -- Max 2 inline suggestions
          },
        },
      },
    },
  },
}
