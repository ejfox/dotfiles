return {
  "Shatur/neovim-ayu",
  keys = {
    {
      "<leader>ut",
      function()
        if vim.o.background == "dark" then
          vim.o.background = "light"
          vim.cmd("colorscheme ayu-light")
        else
          vim.o.background = "dark"
          vim.cmd("colorscheme ayu-dark")
        end
      end,
      desc = "Toggle light/dark theme",
    },
  },
}