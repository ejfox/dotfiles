return {
  "Shatur/neovim-ayu",
  lazy = false,
  priority = 1000,
  config = function()
    require("ayu").setup({
      mirage = false, -- or true if you want the "mirage" variant
      terminal = true,
      overrides = {},
    })
  end,
}
