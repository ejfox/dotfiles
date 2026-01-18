return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function()
      -- Helper function to get path with context (2 preceding dirs)
      local function context_path()
        local path = vim.fn.expand("%:~:.")
        local parts = vim.split(path, "/")

        -- Show last 3 parts (2 dirs + filename) for better context
        if #parts > 3 then
          return parts[#parts-2] .. "/" .. parts[#parts-1] .. "/" .. parts[#parts]
        elseif #parts > 2 then
          return parts[#parts-1] .. "/" .. parts[#parts]
        elseif #parts > 1 then
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
        local lsp_icons = {
          volar = "󰡄",  -- Vue icon (alternative)
          vtsls = "󰛦",  -- TypeScript icon
          tsserver = "󰛦",  -- TypeScript icon
          eslint = "󰱺",  -- ESLint icon
          copilot = "",  -- Copilot
          lua_ls = "",  -- Lua
          pyright = "",  -- Python
          rust_analyzer = "",  -- Rust
        }
        
        local icons = {}
        for _, client in ipairs(clients) do
          -- Skip copilot from display
          if client.name ~= "copilot" then
            local icon = lsp_icons[client.name] or "●"
            table.insert(icons, icon)
          end
        end
        
        if #icons == 0 then
          return ""  -- No text when no LSP
        end
        
        return table.concat(icons, " ")
      end

      -- Line count
      local function line_count()
        return vim.api.nvim_buf_line_count(0) .. "L"
      end

      -- Copilot status (AI ready indicator)
      local function copilot_status()
        local ok, copilot = pcall(require, "copilot.client")
        if not ok then return "" end

        -- Check if copilot is attached to buffer
        local attached = false
        for _, client in ipairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
          if client.name == "copilot" then
            attached = true
            break
          end
        end

        if not attached then
          return "" -- Hidden when not active
        end

        -- AI ready - simple text since nerdfonts not working
        return "AI"
      end

      -- Hotreload status - only shows when file was just reloaded
      local function hotreload_status()
        -- Check for recent reload flag
        if vim.g.file_just_reloaded then
          return "⟳" -- Just reloaded by Claude Code
        end
        return ""
      end

      -- Modified/unsaved changes indicator
      local function modified_status()
        if vim.bo.modified then
          return "●" -- Unsaved changes
        end
        return ""
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
              context_path,
              symbols = { modified = " ◆", readonly = " ◇", unnamed = "[No Name]" },
            },
          },
          lualine_x = {
            { modified_status, color = { fg = "#ff6666" } },   -- Red dot (unsaved!)
            { hotreload_status, color = { fg = "#66ff66" } },  -- Green (just reloaded)
            { copilot_status, color = { fg = "#888888" } },    -- Dim gray (AI ready)
            { line_count },
            { minimal_diagnostics },
            { lsp_status },
          },
          lualine_y = {},
          lualine_z = {},
        },
        inactive_sections = {
          lualine_c = { context_path },
          lualine_x = {},
        },
      }
    end,
  },
}