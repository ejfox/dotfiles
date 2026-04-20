return {
  {
    "m00qek/baleia.nvim",
    version = "*",
    cmd = "BaleiaColorize",
    config = function()
      vim.g.baleia = require("baleia").setup({})
      vim.api.nvim_create_user_command("BaleiaColorize", function()
        vim.g.baleia.once(vim.api.nvim_get_current_buf())
      end, { bang = true })
    end,
  },
}
