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
          -- Web
          volar = "V",            -- Vue
          vtsls = "TS",           -- TypeScript
          tsserver = "TS",        -- TypeScript
          eslint = "◆",           -- ESLint
          tailwindcss = "tw",     -- Tailwind
          html = "H",             -- HTML
          cssls = "css",          -- CSS
          jsonls = "{}",          -- JSON
          emmet_ls = "em",        -- Emmet
          svelte = "sv",          -- Svelte
          astro = "✦",            -- Astro

          -- Languages
          lua_ls = "lua",         -- Lua
          pyright = "py",         -- Python
          rust_analyzer = "rs",   -- Rust
          gopls = "go",           -- Go
          clangd = "C",           -- C/C++
          ruby_lsp = "rb",        -- Ruby
          solargraph = "rb",      -- Ruby

          -- Tools
          copilot = "",           -- Copilot (hidden separately)
          dockerls = "🐳",         -- Docker
          yamlls = "yml",         -- YAML
          bashls = "$",           -- Bash
          marksman = "md",        -- Markdown
        }
        
        local icons = {}
        for _, client in ipairs(clients) do
          -- Skip copilot from display
          if client.name ~= "copilot" then
            local icon = lsp_icons[client.name]
            if icon then table.insert(icons, icon) end
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
          return "󰽂" -- Unsaved changes (delta)
        end
        return ""
      end

      -- Vulpes mode colors - entire bar changes
      local vulpes_red = "#e60067"
      local vulpes_blue = "#6eedf7"  -- cyberpunk teal
      local vulpes_bg = "#0d0d0d"
      local vulpes_fg = "#f2cfdf"

      local vulpes_theme = {
        normal = {
          a = { fg = vulpes_fg, bg = vulpes_bg },
          b = { fg = vulpes_fg, bg = vulpes_bg },
          c = { fg = vulpes_fg, bg = vulpes_bg },
          x = { fg = vulpes_fg, bg = vulpes_bg },
          y = { fg = vulpes_fg, bg = vulpes_bg },
          z = { fg = vulpes_fg, bg = vulpes_bg },
        },
        insert = {
          a = { fg = "#000000", bg = vulpes_red },
          b = { fg = "#000000", bg = vulpes_red },
          c = { fg = "#000000", bg = vulpes_red },
          x = { fg = "#000000", bg = vulpes_red },
          y = { fg = "#000000", bg = vulpes_red },
          z = { fg = "#000000", bg = vulpes_red },
        },
        visual = {
          a = { fg = "#000000", bg = vulpes_blue },
          b = { fg = "#000000", bg = vulpes_blue },
          c = { fg = "#000000", bg = vulpes_blue },
          x = { fg = "#000000", bg = vulpes_blue },
          y = { fg = "#000000", bg = vulpes_blue },
          z = { fg = "#000000", bg = vulpes_blue },
        },
        replace = {
          a = { fg = "#000000", bg = "#ff1aca" },
          b = { fg = "#000000", bg = "#ff1aca" },
          c = { fg = "#000000", bg = "#ff1aca" },
          x = { fg = "#000000", bg = "#ff1aca" },
          y = { fg = "#000000", bg = "#ff1aca" },
          z = { fg = "#000000", bg = "#ff1aca" },
        },
        command = {
          a = { fg = "#000000", bg = "#ffaa00" },
          b = { fg = "#000000", bg = "#ffaa00" },
          c = { fg = "#000000", bg = "#ffaa00" },
          x = { fg = "#000000", bg = "#ffaa00" },
          y = { fg = "#000000", bg = "#ffaa00" },
          z = { fg = "#000000", bg = "#ffaa00" },
        },
        inactive = {
          a = { fg = "#735865", bg = vulpes_bg },
          b = { fg = "#735865", bg = vulpes_bg },
          c = { fg = "#735865", bg = vulpes_bg },
          x = { fg = "#735865", bg = vulpes_bg },
          y = { fg = "#735865", bg = vulpes_bg },
          z = { fg = "#735865", bg = vulpes_bg },
        },
      }

      return {
        options = {
          theme = vulpes_theme,
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