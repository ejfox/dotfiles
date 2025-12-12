return {
  "folke/noice.nvim",
  opts = {
    notify = {
      enabled = true,
      view = "notify",
    },
    -- Configure the notify view - force nvim-notify, skip snacks
    views = {
      notify = {
        backend = "notify",           -- FORCE nvim-notify, not snacks
        render = "wrapped-compact",   -- WRAP ALL THE TEXT
      },
    },
  },
}
