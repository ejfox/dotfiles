-- nvim-cmp for LSP/buffer completions ONLY (no AI popup)
-- AI completions happen via inline ghost text (see copilot-inline.lua)
return {
  {
    "hrsh7th/nvim-cmp",
    version = false,
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",    -- LSP completions
      "hrsh7th/cmp-buffer",      -- Buffer word completions
      "hrsh7th/cmp-path",        -- File path completions
    },
    opts = function()
      local cmp = require("cmp")

      return {
        -- ONLY LSP/Buffer/Path (NO AI in popup)
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 100 },   -- Language server
          { name = "buffer",   priority = 70 },    -- Words from buffers
          { name = "path",     priority = 60 },    -- File paths
        }),

        -- Minimal UI
        window = {
          completion = {
            border = "rounded",
            winhighlight = "Normal:Normal,FloatBorder:Normal,CursorLine:Visual",
          },
        },

        -- Simple formatting
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            local kind_icons = {
              Text = "󰉿", Method = "󰆧", Function = "󰊕",
              Variable = "󰀫", Class = "󰠱", Interface = "󰜰",
              Keyword = "󰌋", File = "󰈙", Folder = "󰉋",
            }
            vim_item.kind = (kind_icons[vim_item.kind] or "") .. " " .. vim_item.kind
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              buffer = "[Buf]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },

        -- Keybindings (Ctrl+n/p for LSP completion)
        mapping = {
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        },

        -- Performance
        performance = {
          debounce = 60,
          throttle = 30,
        },
      }
    end,
  },
}
