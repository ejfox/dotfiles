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

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim base
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Language extras
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.vue" },

    -- User plugins (lua/plugins/*.lua)
    { import = "plugins" },
  },

  defaults = {
    lazy = false,
    version = false,
  },

  install = { colorscheme = { "tokyonight", "habamax" } },

  checker = {
    enabled = true,
    notify = false,
  },

  performance = {
    rtp = {
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
