-- ============================================================================
-- nvim-pack: step-D experiment — nvim 0.12 native, no LazyVim, no lazy.nvim
-- ============================================================================
-- Launch:  nvp [files]      (= NVIM_APPNAME=nvim-pack nvim)
-- Main config (~/.config/nvim, LazyVim) is untouched; this one is sandboxed:
-- its own plugins/state live under ~/.local/share/nvim-pack etc.
--
-- Layout follows MiniMax (github.com/nvim-mini/MiniMax, configs/nvim-0.12):
--   init.lua              helpers + mini.nvim bootstrap (this file)
--   plugin/10_options.lua options (ported from the LazyVim config)
--   plugin/20_keymaps.lua keymaps (LSP nav, yank-with-path, .env, git jump)
--   plugin/30_mini.lua    mini.nvim modules (picker, statusline, surround...)
--   plugin/40_plugins.lua treesitter, LSP, copilot, oil, conform, tmux nav
--   colors/               -> ../nvim/colors (shared vulpes themes)
--   nvim-pack-lock.json   vim.pack lockfile (commit it; never hand-edit)
--
-- What's native 0.12 here: vim.pack (plugins), vim.lsp.config/enable (LSP),
-- 'autocomplete' + LSP omnifunc (completion menu), vim.lsp.inline_completion
-- (Copilot ghost text), treesitter highlighting.
--
-- Plugin ops:  :lua vim.pack.update()        review + apply updates
--              :lua vim.pack.del({ 'name' })  after removing it from config
--              :checkhealth vim.pack
-- ============================================================================

_G.Config = {}

local gr = vim.api.nvim_create_augroup('custom-config', {})
Config.new_autocmd = function(event, pattern, callback, desc)
  vim.api.nvim_create_autocmd(event, { group = gr, pattern = pattern, callback = callback, desc = desc })
end

-- Run `callback` after a plugin is installed/updated (build steps).
-- WHY defined before any vim.pack.add(): hooks must exist before the add that
-- installs the plugin, or first-install builds are skipped.
Config.on_packchanged = function(plugin_name, kinds, callback, desc)
  Config.new_autocmd('PackChanged', '*', function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if not (name == plugin_name and vim.tbl_contains(kinds, kind)) then return end
    if not ev.data.active then vim.cmd.packadd(plugin_name) end
    callback(ev.data)
  end, desc)
end

vim.pack.add({ 'https://github.com/nvim-mini/mini.nvim' })

-- Staged loading (mini.misc): `now` = during startup, `later` = right after
-- first draw, `now_if_args` = now when opening files (so LSP/TS are ready).
local misc = require('mini.misc')
Config.now = function(f) misc.safely('now', f) end
Config.later = function(f) misc.safely('later', f) end
Config.now_if_args = vim.fn.argc(-1) > 0 and Config.now or Config.later
Config.on_event = function(ev, f) misc.safely('event:' .. ev, f) end

-- Reuse the main config's mason installs (vtsls, vue_ls, lua_ls, copilot...)
-- instead of running mason here. WHY: keeps the experiment tiny; the LazyVim
-- config keeps them updated.
local mason_bin = vim.fn.expand('~/.local/share/nvim/mason/bin')
if vim.uv.fs_stat(mason_bin) then vim.env.PATH = mason_bin .. ':' .. vim.env.PATH end
Config.mason_pkg = vim.fn.expand('~/.local/share/nvim/mason/packages')
