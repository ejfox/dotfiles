return {
  "stevearc/conform.nvim",
  opts = {
    formatters = {
      prettier = {
        prepend_args = { "--config-precedence", "prefer-file" },
      },
    },
  },
}