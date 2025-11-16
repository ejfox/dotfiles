return {
  {
    "mistweaverco/kulala.nvim",
    ft = "http", -- Only load for .http files
    config = function()
      require("kulala").setup({
        -- Default formatters
        formatters = {
          json = { "jq", "." },
          html = { "prettier", "--parser", "html" },
        },
        -- Icons (minimal)
        icons = {
          inlay = {
            loading = "⏳",
            done = "✅",
            error = "❌",
          },
        },
        -- Display settings
        winbar = true,
        -- Default headers
        default_headers = {},
      })

      -- Keybindings (only in .http files)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "http",
        callback = function()
          local opts = { buffer = true, silent = true }
          vim.keymap.set("n", "<CR>", ":lua require('kulala').run()<CR>", vim.tbl_extend("force", opts, { desc = "Execute request" }))
          vim.keymap.set("n", "[r", ":lua require('kulala').jump_prev()<CR>", vim.tbl_extend("force", opts, { desc = "Previous request" }))
          vim.keymap.set("n", "]r", ":lua require('kulala').jump_next()<CR>", vim.tbl_extend("force", opts, { desc = "Next request" }))
          vim.keymap.set("n", "<leader>ri", ":lua require('kulala').inspect()<CR>", vim.tbl_extend("force", opts, { desc = "Inspect request" }))
          vim.keymap.set("n", "<leader>rc", ":lua require('kulala').copy()<CR>", vim.tbl_extend("force", opts, { desc = "Copy as cURL" }))
        end,
      })
    end,
  },
}
