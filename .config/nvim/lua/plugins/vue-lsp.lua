-- Vue/Nuxt LSP - MANUAL ATTACH
-- Since LazyVim opts merging isn't working, manually attach vtsls to Vue files

return {
  {
    "rushjs1/nuxt-goto.nvim",
    ft = "vue",
  },

  -- Manually configure vtsls for Vue after everything loads
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "vue",
        callback = function(args)
          -- Check if vtsls is already attached
          for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
            if client.name == "vtsls" then
              return -- Already attached
            end
          end

          -- Manually start vtsls for this buffer
          local vue_ts_plugin = vim.fn.expand("~/.local/share/nvim/mason/packages/vue-language-server")
            .. "/node_modules/@vue/language-server/node_modules/@vue/typescript-plugin"

          require("lspconfig").vtsls.setup({
            cmd = { vim.fn.expand("~/.local/bin/vtsls-wrapper"), "--stdio" },
            filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
            settings = {
              vtsls = {
                tsserver = {
                  globalPlugins = {
                    {
                      name = "@vue/typescript-plugin",
                      location = vue_ts_plugin,
                      languages = { "javascript", "typescript", "vue" },
                    },
                  },
                },
              },
            },
          })

          -- Force attach to this buffer
          vim.cmd("LspStart vtsls")
        end,
      })
    end,
  },
}
