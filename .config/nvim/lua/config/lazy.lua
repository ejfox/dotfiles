-- ============================================================================
-- LAZY.NVIM BOOTSTRAP & PLUGIN CONFIGURATION
-- ============================================================================
--
-- Plugin files (19 total):
--
--   CORE UI
--   ├── theming.lua        - Colorscheme, auto dark/light, twilight dimming
--   ├── notifications.lua  - nvim-notify + noice routing
--   ├── snacks.lua         - Dashboard + picker layouts
--   └── minimal-*.lua      - Statusline, telescope config
--
--   EDITING
--   ├── focus.lua          - Zen mode, prose mode
--   ├── utilities.lua      - Surround, tmux-navigator, prettier
--   ├── mini.lua           - Animations, inline diff
--   └── nvim-ufo.lua       - Code folding
--
--   GIT
--   └── git.lua            - Gitsigns, conflicts, oil git status
--
--   LSP/LANGUAGES
--   ├── vue-lsp.lua        - Vue/Nuxt (vtsls + @vue/typescript-plugin)
--   ├── svelte.lua         - Svelte LSP
--   └── nvim-cmp-lean.lua  - Completion (LSP, buffer, path)
--
--   TOOLS
--   ├── oil.lua            - File explorer
--   ├── nvim-dap.lua       - Debugger
--   ├── obsidian.lua       - Note-taking
--   ├── copilot-inline.lua - AI suggestions
--   ├── claude-code-workflow.lua - Copy code with paths
--   └── usage-logging.lua  - Activity tracking
--
-- ============================================================================

-- WHY: Compute the Lazy.nvim install path inside Neovim's data dir so it works across machines.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- WHY: Bootstrap Lazy.nvim on first run so plugin setup can proceed automatically.
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    -- WHY: Fail fast with a clear message so users aren't left with a broken editor.
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
-- WHY: Prepend Lazy.nvim to runtimepath so it can load before plugins.
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- WHY: Pull in LazyVim defaults as the foundation.
    -- LazyVim base
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- WHY: Add official language presets for Typescript/Vue so LSP, treesitter, etc. are prewired.
    -- Language extras
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.vue" },

    -- WHY: Load local plugin specs in lua/plugins for customizations.
    -- User plugins (lua/plugins/*.lua)
    { import = "plugins" },
  },

  defaults = {
    -- WHY: Eager-load plugins by default; set version=false for latest commit updates.
    lazy = false,
    version = false,
  },

  -- WHY: Ensure a usable colorscheme on first install before user theme loads.
  install = { colorscheme = { "tokyonight", "habamax" } },

  checker = {
    -- WHY: Auto-check for updates quietly so you can decide when to apply.
    enabled = true,
    notify = false,
  },

  performance = {
    rtp = {
      -- WHY: Disable rarely used builtin plugins to reduce startup cost.
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
