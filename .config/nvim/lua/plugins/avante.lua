return {
  {
    "yetone/avante.nvim",
    build = "make",  -- Requires cargo; uses prebuilt binaries if not available
    event = "VeryLazy",
    version = false,  -- Important: never pin to a specific version
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      -- Use project-specific instructions file
      instructions_file = "avante.md",

      -- Configure Claude as the provider
      provider = "claude",
      providers = {
        claude = {
          endpoint = "https://api.anthropic.com",
          -- sonnet-4 balances speed with quality; opus for deeper analysis
          model = "claude-sonnet-4-20250514",
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,           -- Balanced: reliable but slightly creative
            max_tokens = 20480,           -- Allow longer responses for complex refactors
          },
        },
      },

      -- Behavior settings
      behavior = {
        auto_suggestions = false,         -- Don't auto-apply; review first
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        support_paste_from_clipboard = true,
      },

      -- Sidebar configuration (chat interface)
      sidebar = {
        is_open_on_start = false,         -- Don't open sidebar by default
        set_number = false,               -- Don't show line numbers in sidebar
        width = 40,                       -- Width in characters
        layout = "vertical",              -- Explicit vertical layout
      },

      -- Diff/apply settings (how changes get applied)
      diff = {
        autosave = false,                 -- Review changes before saving
        debug = false,
      },

      -- Windows/UI styling
      windows = {
        wrap = true,
        type = "split",                   -- Use split window, not default
        position = "right",               -- Position sidebar on right
      },

      -- Mappings for common operations
      mappings = {
        --- When you press this key in Normal mode, ask for input
        ask = "<leader>aa",
        --- When you press this key in Normal mode, ask for input in a new chat
        edit = "<leader>ae",
        --- When you press this key in Normal mode, refactor the current code
        refresh = "<leader>ar",
      },

      --- Optional: If claude.md exists in the root of the project, avante will reference it
      file_selector = {
        provider = "fzf",
      },
    },
  },
}
