-- Vue/Nuxt
-- WHY no manual vtsls attach: the old FileType -> `:LspStart vtsls` hack broke on
-- nvim 0.12 (:LspStart is gone). LazyVim's lang.vue extra (enabled in lazy.lua)
-- wires vtsls + @vue/typescript-plugin + vue_ls via native vim.lsp.config.

return {
  {
    "rushjs1/nuxt-goto.nvim",
    ft = "vue",
  },
}
