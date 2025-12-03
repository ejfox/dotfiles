return {
  {
    "hrsh7th/nvim-cmp",
    version = false,
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",    -- LSP completions
      "hrsh7th/cmp-buffer",      -- Buffer word completions
      "hrsh7th/cmp-path",        -- File path completions
      "hrsh7th/cmp-cmdline",     -- Command line completions
    },
    opts = function()
      vim.g.ai_cmp = true  -- Signal Copilot to integrate with cmp

      local cmp = require("cmp")

      return {
        -- Source priority: Copilot > LSP > Buffer > Path
        sources = cmp.config.sources({
          { name = "copilot",  priority = 100 },  -- AI line/function completions
          { name = "nvim_lsp", priority = 90 },   -- Language server completions
          { name = "buffer",   priority = 70 },   -- Words from open buffers
          { name = "path",     priority = 60 },   -- File paths
        }),

        -- Minimal UI: simple rounded borders, no icons
        window = {
          completion = {
            border = "rounded",
            winhighlight = "Normal:Normal,FloatBorder:Normal,CursorLine:Visual",
          },
          documentation = {
            border = "rounded",
          },
        },

        -- Formatting with nerd font icons + source labels
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            -- Nerd font icons for completion kinds
            local kind_icons = {
              Text = "󰉿",
              Method = "󰆧",
              Function = "󰊕",
              Constructor = "󰒓",
              Field = "󰜢",
              Variable = "󰀫",
              Class = "󰠱",
              Interface = "󰜰",
              Module = "󰆦",
              Property = "󰜢",
              Unit = "󰑭",
              Value = "󰎠",
              Enum = "󰎦",
              Keyword = "󰌋",
              Snippet = "󰘌",
              Color = "󰏘",
              File = "󰈙",
              Reference = "󰈇",
              Folder = "󰉋",
              EnumMember = "󰎦",
              Constant = "󰏿",
              Struct = "󰙅",
              Event = "󰟓",
              Operator = "󰆕",
              TypeParameter = "󰅲",
              Copilot = "",
            }

            vim_item.kind = (kind_icons[vim_item.kind] or "") .. " " .. vim_item.kind
            vim_item.menu = ({
              copilot = "[AI]",
              nvim_lsp = "[LSP]",
              buffer = "[Buf]",
              path = "[Path]",
            })[entry.source.name]

            return vim_item
          end,
        },

        -- Native nvim-cmp keybindings (transferrable knowledge)
        mapping = {
          -- Standard cmp preset bindings
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),

          -- VSCode-style: Tab/Enter to accept (your comfort zone)
          ["<Tab>"] = cmp.mapping.confirm({ select = true }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        },

        -- Performance
        performance = {
          max_view_entries = 200,
          debounce = 60,
          throttle = 30,
        },
      }
    end,

    config = function(_, opts)
      local cmp = require("cmp")
      cmp.setup(opts)

      -- Command line completion
      cmp.setup.cmdline(":", {
        sources = cmp.config.sources({
          { name = "path" },
          { name = "cmdline" },
        }),
      })

      cmp.setup.cmdline("/", {
        sources = { { name = "buffer" } },
      })
    end,
  },
}
