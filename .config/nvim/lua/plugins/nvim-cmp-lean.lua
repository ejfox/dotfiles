-- blink.cmp UI overrides (base config from lazyvim.plugins.extras.coding.blink)
-- AI completions happen via inline ghost text (see copilot-inline.lua)

-- Keep copilot as inline ghost text, not in the completion popup
vim.g.ai_cmp = false

return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          border = "none",
          max_height = 20,
          winhighlight = "Normal:BlinkCmpMenu,CursorLine:BlinkCmpMenuSelection,FloatBorder:BlinkCmpMenuBorder",
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name" },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 100,
          window = {
            border = "none",
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder",
          },
        },
        ghost_text = {
          enabled = false, -- copilot handles ghost text
        },
      },
      signature = {
        enabled = true,
        window = {
          border = "single",
          winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureBorder",
          treesitter_highlighting = true,
        },
      },
      keymap = {
        preset = "enter",
        ["<CR>"] = { "accept", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-Space>"] = { "show" },
        ["<C-e>"] = { "cancel", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        -- Tab stays free for copilot
        ["<Tab>"] = { "fallback" },
        ["<S-Tab>"] = { "fallback" },
      },
    },
    init = function()
      -- Vulpes-matched highlights for blink.cmp
      -- Uses shared palette colors: #73264a for passive borders (tmux/lazygit/yazi),
      -- #e60067 for active accents, #6b1a3d for bloom-friendly selections
      local function set_blink_highlights()
        local hl = vim.api.nvim_set_hl
        hl(0, "BlinkCmpMenu", { bg = "#000000", fg = "#f2cfdf" })
        hl(0, "BlinkCmpMenuBorder", { bg = "#000000", fg = "#0d0d0d" })
        hl(0, "BlinkCmpMenuSelection", { bg = "#6b1a3d", fg = "#ffffff" })
        hl(0, "BlinkCmpLabel", { fg = "#f2cfdf" })
        hl(0, "BlinkCmpLabelMatch", { fg = "#e60067", bold = true })
        hl(0, "BlinkCmpLabelDescription", { fg = "#735865" })
        hl(0, "BlinkCmpKind", { fg = "#735865" })
        hl(0, "BlinkCmpKindFunction", { fg = "#ffffff" })
        hl(0, "BlinkCmpKindMethod", { fg = "#ffffff" })
        hl(0, "BlinkCmpKindVariable", { fg = "#6eedf7" })
        hl(0, "BlinkCmpKindClass", { fg = "#e60067" })
        hl(0, "BlinkCmpKindInterface", { fg = "#e60067" })
        hl(0, "BlinkCmpKindKeyword", { fg = "#ff1aca" })
        hl(0, "BlinkCmpKindSnippet", { fg = "#ffaa00" })
        hl(0, "BlinkCmpSource", { fg = "#735865", italic = true })
        hl(0, "BlinkCmpDoc", { bg = "#0d0d0d", fg = "#f2cfdf" })
        hl(0, "BlinkCmpDocBorder", { bg = "#0d0d0d", fg = "#0d0d0d" })
        hl(0, "BlinkCmpSignatureHelp", { bg = "#0d0d0d", fg = "#f2cfdf" })
        hl(0, "BlinkCmpSignatureBorder", { bg = "#0d0d0d", fg = "#73264a" })
      end

      set_blink_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_blink_highlights })
    end,
  },
}
