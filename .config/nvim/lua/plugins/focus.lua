-- ============================================================================
-- FOCUS: Zen mode and prose mode for distraction-free editing
-- Consolidates: zen-mode.lua, prose.lua
-- ============================================================================

return {
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>Z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
      {
        "<leader>uw",
        function()
          if vim.wo.wrap then
            vim.wo.wrap = false
            vim.wo.linebreak = false
            vim.notify("Wrap OFF")
          else
            vim.wo.wrap = true
            vim.wo.linebreak = true
            vim.notify("Wrap ON")
          end
        end,
        desc = "Toggle word wrap",
      },
      {
        "<leader>up",
        function()
          require("zen-mode").toggle({
            window = {
              width = 38,
              options = {
                signcolumn = "no",
                number = false,
                relativenumber = false,
                cursorline = false,
                wrap = true,
                linebreak = true,
              },
            },
            plugins = { twilight = { enabled = true }, tmux = { enabled = true } },
          })
        end,
        desc = "Prose mode (34ch narrow)",
      },
    },
    config = function()
      require("zen-mode").setup({
        window = {
          backdrop = 1,
          width = 100,
          height = 0.95,
          options = {
            signcolumn = "no",
            number = false,
            relativenumber = false,
            cursorline = false,
          },
        },
        plugins = {
          twilight = { enabled = true },
          gitsigns = { enabled = false },
          tmux = { enabled = true },
        },
        on_open = function() vim.fn.system("tmux resize-pane -Z") end,
        on_close = function() vim.fn.system("tmux resize-pane -Z") end,
      })
    end,
  },
}
