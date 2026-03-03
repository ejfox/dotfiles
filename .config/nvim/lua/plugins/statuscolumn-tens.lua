-- Absolute line numbers every 10 lines in accent color
-- Every 10th line shows absolute lnum in grey instead of relative number

return {
  {
    "folke/snacks.nvim",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          local function set_hl()
            vim.api.nvim_set_hl(0, "StatusColumnTens", { fg = "#666666" })
          end
          set_hl()
          vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

          -- Wrap Snacks statuscolumn if available
          local ok, sc = pcall(require, "snacks.statuscolumn")
          if ok and sc and sc.get then
            local orig_get = sc.get
            sc.get = function(...)
              local result = orig_get(...)
              if vim.v.relnum ~= 0 and vim.v.lnum % 10 == 0 and vim.v.virtnum == 0 then
                local lnum_str = tostring(vim.v.lnum)
                result = result:gsub(
                  tostring(vim.v.relnum),
                  "%%#StatusColumnTens#" .. lnum_str .. "%%*",
                  1
                )
              end
              return result
            end
          end
        end,
      })
    end,
  },
}
