-- mini.diff - inline diff visualization
-- Complements gitsigns with overlay for deleted lines
return {
  {
    "nvim-mini/mini.diff",
    event = "VeryLazy",
    opts = {
      -- Use overlay to show deleted lines inline (gitsigns handles signs)
      view = {
        style = "sign", -- 'sign' or 'number'
        signs = { add = "▎", change = "▎", delete = "" },
        priority = 199,
      },
      -- Source: use git
      source = nil, -- nil = auto-detect (git)
      -- Delay for async diff computation
      delay = {
        text_change = 200,
      },
      -- Mappings
      mappings = {
        apply = "gh",      -- Apply hunk
        reset = "gH",      -- Reset hunk
        textobject = "gh", -- Hunk textobject
        goto_first = "[H",
        goto_prev = "[h",
        goto_next = "]h",
        goto_last = "]H",
      },
    },
    keys = {
      { "<leader>go", function() require("mini.diff").toggle_overlay() end, desc = "Toggle diff overlay" },
    },
    config = function(_, opts)
      require("mini.diff").setup(opts)
      -- Enable overlay by default after short delay (let buffers load)
      vim.defer_fn(function()
        pcall(require("mini.diff").toggle_overlay)
      end, 100)
    end,
  },
}
