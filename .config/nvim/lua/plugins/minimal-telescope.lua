return {
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        -- Remove all borders
        borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
        -- Minimal prompts
        prompt_prefix = " ",
        selection_caret = "▸ ",
        entry_prefix = "  ",
        -- Clean layout
        layout_strategy = "flex",
        layout_config = {
          prompt_position = "top",
          horizontal = {
            preview_width = 0.55,
          },
        },
        -- Minimal icons
        file_ignore_patterns = { "node_modules", ".git/" },
        path_display = { "smart" },
        -- Performance
        preview = {
          hide_on_startup = false,
        },
        -- Custom keybindings
        mappings = {
          i = {
            ["<C-v>"] = false,  -- disable default
            ["<C-_>"] = "select_vertical",
          },
        },
      },
      pickers = {
        find_files = {
          find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
        },
        buffers = {
          show_all_buffers = true,
          sort_lastused = true,
          mappings = {
            i = {
              ["<c-d>"] = "delete_buffer",
            },
          },
        },
      },
    },
  },
}