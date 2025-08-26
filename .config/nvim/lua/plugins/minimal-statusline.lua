return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function()
      -- Helper function to get one level of path
      local function one_level_path()
        local path = vim.fn.expand("%:~:.")
        local parts = vim.split(path, "/")
        if #parts > 1 then
          return parts[#parts-1] .. "/" .. parts[#parts]
        end
        return path
      end

      -- Helper function for minimal diagnostics
      local function minimal_diagnostics()
        local diagnostics = vim.diagnostic.get(0)
        local counts = { 0, 0, 0, 0 } -- error, warn, info, hint
        
        for _, d in ipairs(diagnostics) do
          counts[d.severity] = counts[d.severity] + 1
        end
        
        local parts = {}
        if counts[1] > 0 then table.insert(parts, counts[1]) end
        if counts[2] > 0 then table.insert(parts, counts[2]) end
        if counts[4] > 0 then table.insert(parts, counts[4]) end -- hints
        
        if #parts == 0 then return "" end
        return table.concat(parts, "/")
      end

      -- Helper function for LSP status
      local function lsp_status()
        local clients = vim.lsp.get_active_clients({ bufnr = 0 })
        local lsp_names = {}
        
        for _, client in ipairs(clients) do
          -- Skip copilot from LSP display
          if client.name ~= "copilot" then
            table.insert(lsp_names, client.name)
          end
        end
        
        if #lsp_names == 0 then
          return "NO LSP"
        end
        
        -- Return first LSP name, or multiple if more than one
        if #lsp_names == 1 then
          return lsp_names[1]
        else
          return table.concat(lsp_names, ",")
        end
      end

      -- Line count
      local function line_count()
        return vim.api.nvim_buf_line_count(0) .. "L"
      end

      return {
        options = {
          theme = "auto",
          component_separators = "",
          section_separators = "",
          globalstatus = true,
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            { 
              one_level_path,
              symbols = { modified = " ◆", readonly = " ◇", unnamed = "[No Name]" },
            },
          },
          lualine_x = {
            { line_count },
            { minimal_diagnostics },
            { lsp_status },
          },
          lualine_y = {},
          lualine_z = {},
        },
        inactive_sections = {
          lualine_c = { one_level_path },
          lualine_x = {},
        },
      }
    end,
  },
}