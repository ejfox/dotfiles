-- ============================================================================
-- OIL.NVIM: File explorer as a buffer
-- ============================================================================
-- WHY oil.nvim: Instead of a sidebar file tree (NERDTree, neo-tree), oil opens
-- directories AS BUFFERS. This means:
--   - Delete a line = delete the file
--   - Edit a line = rename the file
--   - All vim motions work (search, visual select, etc.)
--   - No sidebar eating screen space
--
-- Key insight: The filesystem IS the buffer. Vim muscle memory applies.
-- ============================================================================

return {
  {
    "stevearc/oil.nvim",
    lazy = false,  -- WHY: Load immediately to hijack directory buffers (vim .)
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        -- WHY true: Makes oil the default when opening directories
        default_file_explorer = true,

        -- WHY just icon: Cleaner display, less noise
        columns = {
          "icon",
          -- "permissions",
          -- "size",
          -- "mtime",
        },

        -- WHY: Don't prompt for simple renames/deletes
        skip_confirm_for_simple_edits = true,

        -- WHY signcolumn: Shows git status via oil-git-status plugin
        win_options = {
          signcolumn = "yes:2",
        },

        -- Keymaps in oil buffer (these only work inside oil)
        keymaps = {
          ["g?"] = "actions.show_help",     -- Help
          ["<CR>"] = "actions.select",       -- Open file/dir
          ["<C-s>"] = "actions.select_vsplit", -- Open in vertical split
          ["<C-h>"] = "actions.select_split",  -- Open in horizontal split
          ["<C-t>"] = "actions.select_tab",    -- Open in new tab
          ["<C-p>"] = "actions.preview",       -- Preview file
          ["<C-c>"] = "actions.close",         -- Close oil
          ["<C-l>"] = "actions.refresh",       -- Refresh listing
          ["-"] = "actions.parent",            -- Go up to parent dir
          ["_"] = "actions.open_cwd",          -- Open cwd
          ["`"] = "actions.cd",                -- :cd to this dir
          ["~"] = "actions.tcd",               -- :tcd to this dir
          ["gs"] = "actions.change_sort",      -- Change sort order
          ["gx"] = "actions.open_external",    -- Open with system app
          ["g."] = "actions.toggle_hidden",    -- Toggle dotfiles
          ["g\\"] = "actions.toggle_trash",    -- Toggle trash view
        },
        use_default_keymaps = true,

        view_options = {
          show_hidden = false,  -- WHY: Hide dotfiles by default (g. to toggle)
          sort = {
            { "type", "asc" },  -- Directories first
            { "name", "asc" },  -- Then alphabetical
          },
        },

        -- Floating window config (for oil.open_float)
        float = {
          padding = 2,
          max_width = 0,
          max_height = 0,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
        },
      })

      -- THE key binding: `-` opens parent directory from anywhere
      -- Just like vim-vinegar, but better
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },
}
