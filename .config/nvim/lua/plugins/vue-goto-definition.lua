return {
  "catgoose/vue-goto-definition.nvim",
  ft = { "vue", "typescript" },
  opts = {
    filters = {
      auto_imports = true, -- resolve definitions in auto-imports.d.ts
      auto_components = true, -- resolve definitions in components.d.ts
      import_same_file = true, -- filter location list entries referencing an
      -- import in the current file.  See below for details
      declaration = true, -- filter declaration files unless the only location list
      -- item is a declaration file
      duplicate_filename = true, -- dedupe duplicate filenames
    },
    filetypes = { "vue", "typescript" }, -- enabled for filetypes
    detection = { -- framework detection.  Detection functions can be overridden here
      nuxt = function() -- look for .nuxt directory
        return vim.fn.glob(".nuxt/") ~= ""
      end,
      vue3 = function() -- look for vite.config.ts or App.vue
        return vim.fn.filereadable("vite.config.ts") == 1 or vim.fn.filereadable("src/App.vue") == 1
      end,
      priority = { "nuxt", "vue3" }, -- order in which to detect framework
    },
    lsp = {
      override_definition = true, -- override vim.lsp.buf.definition
    },
    debounce = 200,
  },
}
