return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      -- Vue-specific keymaps
      keys[#keys + 1] = {
        "gD",
        function()
          -- Special handling for Vue SFC goto definition
          local params = vim.lsp.util.make_position_params()
          vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, config)
            if err then
              vim.notify("Error: " .. err.message, vim.log.levels.ERROR)
              return
            end
            if not result or vim.tbl_isempty(result) then
              -- Fallback to vue-goto-definition plugin
              vim.cmd("VueGotoDefinition")
              return
            end
            vim.lsp.util.jump_to_location(result[1], "utf-8")
          end)
        end,
        desc = "Goto Definition (Vue-aware)",
        has = "definition",
      }
      
      -- Additional Vue-specific keymaps
      keys[#keys + 1] = { "<leader>cv", "<cmd>VueGotoDefinition<cr>", desc = "Vue Goto Definition" }
      keys[#keys + 1] = { "<leader>ci", vim.lsp.buf.implementation, desc = "Goto Implementation" }
      keys[#keys + 1] = { "<leader>ct", vim.lsp.buf.type_definition, desc = "Goto Type Definition" }
    end,
  },

  -- Vue-specific commands
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>v", group = "vue" },
      },
    },
  },

  -- Add commands for Vue development in a separate config
  {
    "folke/lazy.nvim",
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "vue" },
        callback = function()
          -- Vue-specific buffer keymaps
          local opts = { buffer = true, silent = true }
          
          -- Component navigation
          vim.keymap.set("n", "<leader>vt", function()
            -- Jump to template section
            vim.fn.search("^<template>", "w")
          end, vim.tbl_extend("force", opts, { desc = "Go to template" }))
          
          vim.keymap.set("n", "<leader>vs", function()
            -- Jump to script section
            vim.fn.search("^<script", "w")
          end, vim.tbl_extend("force", opts, { desc = "Go to script" }))
          
          vim.keymap.set("n", "<leader>vy", function()
            -- Jump to style section
            vim.fn.search("^<style", "w")
          end, vim.tbl_extend("force", opts, { desc = "Go to style" }))
          
          -- Quick actions
          vim.keymap.set("n", "<leader>vr", function()
            -- Restart Vue LSP
            vim.cmd("LspRestart volar")
            vim.notify("Volar LSP restarted", vim.log.levels.INFO)
          end, vim.tbl_extend("force", opts, { desc = "Restart Volar LSP" }))
        end,
      })
    end,
  },
}