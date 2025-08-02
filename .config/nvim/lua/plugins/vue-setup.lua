-- Vue Setup Helper
return {
  {
    "williamboman/mason.nvim",
    build = function()
      -- Ensure Vue TypeScript plugin is installed after Mason installs vue-language-server
      vim.defer_fn(function()
        local mason_path = vim.fn.stdpath("data") .. "/mason"
        local vue_ts_plugin_path = mason_path .. "/packages/vue-language-server/node_modules/@vue/typescript-plugin"
        
        -- Check if the plugin exists
        if vim.fn.isdirectory(vue_ts_plugin_path) == 0 then
          vim.notify("Installing @vue/typescript-plugin...", vim.log.levels.INFO)
          -- Install in the Mason vue-language-server directory
          local install_cmd = string.format(
            "cd %s/packages/vue-language-server && npm install @vue/typescript-plugin",
            mason_path
          )
          vim.fn.system(install_cmd)
          vim.notify("@vue/typescript-plugin installed!", vim.log.levels.INFO)
        end
      end, 1000)
    end,
  },
  
  -- Auto-commands for Vue development
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Create autocmd to check Vue setup
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "vue",
        callback = function()
          -- Check if both LSPs are attached
          vim.defer_fn(function()
            local clients = vim.lsp.get_active_clients({ bufnr = 0 })
            local has_volar = false
            local has_tsserver = false
            
            for _, client in ipairs(clients) do
              if client.name == "volar" then has_volar = true end
              if client.name == "tsserver" then has_tsserver = true end
            end
            
            if not has_volar then
              vim.notify("Volar not attached! Run :LspStart volar", vim.log.levels.WARN)
            end
            if not has_tsserver then
              vim.notify("TSServer not attached! Check your config", vim.log.levels.WARN)
            end
          end, 500)
        end,
      })
    end,
  },
}