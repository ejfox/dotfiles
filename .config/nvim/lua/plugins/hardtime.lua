return {
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    enabled = false,  -- Disable for now; re-enable when you want to train vim habits
    opts = {
      restriction_mode = "block",
      disabled_keys = {
        ["<Up>"] = {},
        ["<Down>"] = {},
        ["<Left>"] = {},
        ["<Right>"] = {},
      },
    },
  },
}
