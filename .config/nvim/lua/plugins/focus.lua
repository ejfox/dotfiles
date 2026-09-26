-- ============================================================================
-- FOCUS: Zen mode and prose mode for distraction-free editing
-- WHY snacks.zen: replaces folke/zen-mode.nvim + twilight.nvim (snacks is
-- already loaded; its zen toggles snacks.dim, which replaces twilight).
-- ============================================================================

-- WHY tmux zoom: matches the old zen-mode on_open/on_close behavior so the
-- nvim pane fills the tmux window while focused.
local function tmux_zoom()
  if vim.env.TMUX then vim.fn.system("tmux resize-pane -Z") end
end

local zen_wo = {
  signcolumn = "no",
  number = false,
  relativenumber = false,
  cursorline = false,
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      zen = {
        toggles = { dim = true, git_signs = false, mini_diff_signs = false },
        win = { width = 100, wo = zen_wo },
        on_open = tmux_zoom,
        on_close = tmux_zoom,
      },
    },
    keys = {
      { "<leader>Z", function() Snacks.zen() end, desc = "Zen Mode" },
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
          Snacks.zen({
            win = {
              width = 38,
              wo = vim.tbl_extend("force", zen_wo, { wrap = true, linebreak = true }),
            },
          })
        end,
        desc = "Prose mode (34ch narrow)",
      },
    },
  },
}
