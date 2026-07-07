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

      -- Vulpes mode colors — reactive to vim.o.background.
      -- Light translates dark roles preserving the system:
      --   pink bg = brand (insert)
      --   teal bg = inverse hue (visual)
      --   sepia/amber bg = command (warm warn)
      --   bg/fg = bg_alt and ink.primary (raised surface)
      local function build_vulpes_theme()
        local is_dark = vim.o.background == "dark"
        local c = is_dark and {
          bg       = "#0d0d0d",  -- bg_alt
          fg       = "#f2cfdf",  -- soft pink-cream
          inactive = "#735865",  -- linenr
          insert_bg   = "#e60067", insert_fg   = "#000000",  -- brand pink + black
          visual_bg   = "#6eedf7", visual_fg   = "#000000",  -- bright teal + black
          replace_bg  = "#ff1aca", replace_fg  = "#000000",  -- magenta keyword + black
          command_bg  = "#ffaa00", command_fg  = "#000000",  -- amber + black
        } or {
          bg       = "#ebe2d6",  -- bg_alt warm tan (raised from white)
          fg       = "#1a0f14",  -- ink.primary
          inactive = "#6a5d60",  -- ink.fade
          insert_bg   = "#a8003c", insert_fg   = "#ffffff",  -- accent.strong + white
          visual_bg   = "#1a5e6e", visual_fg   = "#ffffff",  -- deep teal + white
          replace_bg  = "#7a0044", replace_fg  = "#ffffff",  -- deep magenta + white
          command_bg  = "#8a5530", command_fg  = "#ffffff",  -- sepia + white
        }

        local function row(fg, bg)
          return { a = { fg = fg, bg = bg }, b = { fg = fg, bg = bg }, c = { fg = fg, bg = bg },
                   x = { fg = fg, bg = bg }, y = { fg = fg, bg = bg }, z = { fg = fg, bg = bg } }
        end

        return {
          normal   = row(c.fg, c.bg),
          insert   = row(c.insert_fg,  c.insert_bg),
          visual   = row(c.visual_fg,  c.visual_bg),
          replace  = row(c.replace_fg, c.replace_bg),
          command  = row(c.command_fg, c.command_bg),
          inactive = row(c.inactive, c.bg),
        }
      end

      local vulpes_theme = build_vulpes_theme()

      -- Re-setup lualine when colorscheme changes (auto-dark-mode flips it)
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("VulpesLualineReactive", { clear = true }),
        callback = function()
          vim.schedule(function()
            local ok, lualine = pcall(require, "lualine")
            if not ok then return end
            local cfg = lualine.get_config()
            cfg.options.theme = build_vulpes_theme()
            lualine.setup(cfg)
          end)
        end,
      })

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