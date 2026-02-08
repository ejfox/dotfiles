-- Absolute line numbers every 10 lines in accent color
-- Wraps LazyVim's snacks statuscolumn — every 10th line shows lnum instead of relnum

return {
  {
    "folke/snacks.nvim",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          local orig = LazyVim.statuscolumn
          if not orig then return end

          LazyVim.statuscolumn = function()
            local base = orig()
            if vim.v.relnum ~= 0 and vim.v.lnum % 10 == 0 and vim.v.virtnum == 0 then
              base = base:gsub("%%=(%d+) ", "%%=%%#StatusColumnTens#" .. vim.v.lnum .. "%%* ", 1)
            end
            return base
          end

          local function set_hl()
            vim.api.nvim_set_hl(0, "StatusColumnTens", { fg = "#666666" })
          end
          set_hl()
          vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
        end,
      })
    end,
  },
}
