-- Neovim 0.11 diagnostics configuration
-- Enable virtual lines (show errors below the line, VS Code style)

vim.diagnostic.config({
  -- Enable virtual lines (new in 0.11)
  virtual_lines = true,

  -- Disable inline virtual text (we're using virtual lines instead)
  virtual_text = false,

  -- Keep signs in the gutter
  signs = true,

  -- Show diagnostic info on hover
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },

  -- Update diagnostics in insert mode
  update_in_insert = false,

  -- Sort by severity
  severity_sort = true,

  -- Underline errors
  underline = true,
})

-- Optional: Customize virtual line appearance
-- vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { link = "DiagnosticError" })
-- vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { link = "DiagnosticWarn" })
-- vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { link = "DiagnosticInfo" })
-- vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { link = "DiagnosticHint" })
