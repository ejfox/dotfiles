-- Workflow optimizations for using Claude Code in tmux + nvim
return {
  -- Hot reload system (filesystem watching + auto-reload)
  {
    "nvim-lua/plenary.nvim",
    config = function()
      vim.opt.autoread = true

      -- Initialize hot reload system
      require("custom.hotreload").setup()

      -- Initialize git diff auto-refresh
      require("custom.git-diff-hotreload").setup()
    end,
    keys = {
      -- Copy selection + relative file path
      {
        "<leader>yr",
        function()
          local rel_path = vim.fn.expand("%:.")
          local line_start = vim.fn.line("v")
          local line_end = vim.fn.line(".")
          local lines = vim.fn.getline(line_start, line_end)
          local code = table.concat(lines, "\n")
          local formatted = string.format("%s:%d-%d\n```\n%s\n```", rel_path, line_start, line_end, code)
          vim.fn.setreg("+", formatted)
          vim.notify("Copied with relative path", vim.log.levels.INFO)
        end,
        mode = "v",
        desc = "Yank with relative path",
      },
      -- Copy selection + absolute file path
      {
        "<leader>ya",
        function()
          local abs_path = vim.fn.expand("%:p")
          local line_start = vim.fn.line("v")
          local line_end = vim.fn.line(".")
          local lines = vim.fn.getline(line_start, line_end)
          local code = table.concat(lines, "\n")
          local formatted = string.format("%s:%d-%d\n```\n%s\n```", abs_path, line_start, line_end, code)
          vim.fn.setreg("+", formatted)
          vim.notify("Copied with absolute path", vim.log.levels.INFO)
        end,
        mode = "v",
        desc = "Yank with absolute path",
      },
    },
  },

}
