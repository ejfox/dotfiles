-- Nuxt goto-definition for Vue files.
--
-- NOTE: vtsls + Volar (vue_ls) setup is handled entirely by the LazyVim
-- `lang.vue` extra (see lazyvim.json). Do NOT manually attach vtsls here.
-- The old manual-attach hardcoded the @vue/typescript-plugin path to
--   .../vue-language-server/node_modules/@vue/typescript-plugin
-- but Mason now nests it under @vue/language-server/, so the plugin silently
-- failed to load and vtsls parsed every .vue file as raw TypeScript
-- (a wall of bogus "Cannot find name 'div'" / "Unterminated regex" errors).
-- The extra resolves the correct path via LazyVim.get_pkg_path — let it.

return {
  {
    "rushjs1/nuxt-goto.nvim",
    ft = "vue",
  },
}
