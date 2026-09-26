-- Non-mini plugins + native LSP/completion/Copilot wiring.
local add = vim.pack.add
local now, now_if_args, later = Config.now, Config.now_if_args, Config.later
local map = vim.keymap.set

-- ── Tree-sitter (main branch: parsers only; highlighting is core nvim) ──────
now_if_args(function()
  Config.on_packchanged('nvim-treesitter', { 'update' }, function() vim.cmd('TSUpdate') end, ':TSUpdate')
  add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  })
  local languages = {
    'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline',
    'javascript', 'typescript', 'tsx', 'vue', 'svelte', 'html', 'css',
    'json', 'yaml', 'toml', 'bash', 'python', 'c', 'cpp', 'diff', 'gitcommit', 'regex',
  }
  local isnt_installed = function(lang) return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0 end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then require('nvim-treesitter').install(to_install) end

  local filetypes = {}
  for _, lang in ipairs(languages) do vim.list_extend(filetypes, vim.treesitter.language.get_filetypes(lang)) end
  Config.new_autocmd('FileType', filetypes, function(ev) pcall(vim.treesitter.start, ev.buf) end, 'Start tree-sitter')
end)

-- ── LSP: nvim-lspconfig only ships lsp/*.lua configs; core does the rest ───
now_if_args(function()
  add({ 'https://github.com/neovim/nvim-lspconfig' })

  -- Vue hybrid mode: vtsls handles <script> via @vue/typescript-plugin,
  -- vue_ls handles template/style (see dotfiles CLAUDE.md "Vue/Nuxt LSP").
  vim.lsp.config('vtsls', {
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
    settings = {
      vtsls = {
        tsserver = {
          globalPlugins = {
            {
              name = '@vue/typescript-plugin',
              location = Config.mason_pkg .. '/vue-language-server/node_modules/@vue/language-server',
              languages = { 'vue' },
              configNamespace = 'typescript',
            },
          },
        },
      },
    },
  })
  vim.lsp.config('lua_ls', { settings = { Lua = { workspace = { library = { vim.env.VIMRUNTIME } } } } })

  vim.lsp.enable({ 'lua_ls', 'vtsls', 'vue_ls', 'svelte', 'clangd', 'eslint', 'copilot' })

  vim.diagnostic.config({
    severity_sort = true,
    virtual_text = { spacing = 2, prefix = '●' },
    float = { border = 'single' },
  })

  -- Completion is 'autocomplete' + omnifunc (see 10_options). Enabling
  -- vim.lsp.completion adds snippet expansion + auto-imports on accept.
  Config.new_autocmd('LspAttach', '*', function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
    end
  end, 'LSP completion extras')
end)

-- ── Copilot: native inline completion (ghost text), same keys as main config ─
later(function()
  vim.lsp.inline_completion.enable()

  -- accept-word/accept-line: same port as ~/.config/nvim/lua/plugins/ai.lua
  local function accept_partial(patterns, fallback)
    return function()
      local accepted = vim.lsp.inline_completion.get({
        on_accept = function(item)
          local text = type(item.insert_text) == 'string' and item.insert_text or item.insert_text.value
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          row = row - 1
          local typed = ''
          if item.range and item.range.start_row == row and item.range.start_col <= col then
            typed = vim.api.nvim_buf_get_text(0, row, item.range.start_col, row, col, {})[1]
          end
          if text:sub(1, #typed) ~= typed then return item end
          local rest, chunk = text:sub(#typed + 1), nil
          for _, pat in ipairs(patterns) do chunk = chunk or rest:match(pat) end
          local lines = vim.split(chunk or rest, '\n')
          vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
          vim.api.nvim_win_set_cursor(0, { row + #lines, (#lines == 1 and col or 0) + #lines[#lines] })
          return nil
        end,
      })
      if not accepted then return fallback and vim.keycode(fallback) or '' end
    end
  end

  map('i', '<Tab>', function()
    if not vim.lsp.inline_completion.get() then return '<Tab>' end
  end, { expr = true, desc = 'Accept AI suggestion' })
  map('i', '<C-Right>', accept_partial({ '^%s*[^%w_%s]*[%w_]+', '^%s*%S+' }, '<C-Right>'), { expr = true, desc = 'Accept AI word' })
  map('i', '<C-l>', accept_partial({ '^\n?[^\n]*' }), { expr = true, desc = 'Accept AI line' })
  map({ 'i', 'n' }, '<M-]>', function() vim.lsp.inline_completion.select({ count = 1 }) end, { desc = 'Next AI suggestion' })
  map({ 'i', 'n' }, '<M-[>', function() vim.lsp.inline_completion.select({ count = -1 }) end, { desc = 'Prev AI suggestion' })
end)

-- ── Files / format / nav ─────────────────────────────────────────────────────
now(function()
  add({ 'https://github.com/stevearc/oil.nvim' })
  require('oil').setup({
    default_file_explorer = true,
    columns = { 'icon' },
    skip_confirm_for_simple_edits = true,
    watch_for_changes = true,
    win_options = { signcolumn = 'yes:2' },
    view_options = { show_hidden = false },
    keymaps = {
      ['<C-h>'] = false, ['<C-l>'] = false, ['<C-s>'] = false, -- keep tmux-navigator
      ['<leader>-'] = 'actions.select_split',
      ['<leader>|'] = 'actions.select_vsplit',
      ['<C-p>'] = 'actions.preview',
      ['<C-c>'] = 'actions.close',
      ['`'] = 'actions.cd',
      ['g.'] = 'actions.toggle_hidden',
    },
  })
  map('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })
end)

now(function() add({ 'https://github.com/christoomey/vim-tmux-navigator' }) end)

later(function()
  add({ 'https://github.com/stevearc/conform.nvim' })
  local prettier = { 'prettier' }
  require('conform').setup({
    formatters_by_ft = {
      lua = { 'stylua' },
      javascript = prettier, typescript = prettier, vue = prettier, svelte = prettier,
      css = prettier, html = prettier, json = prettier, yaml = prettier, markdown = prettier,
      sh = { 'shfmt' },
    },
    default_format_opts = { lsp_format = 'fallback' },
    format_on_save = { timeout_ms = 1500 },
  })
  map({ 'n', 'x' }, '<leader>cf', function() require('conform').format() end, { desc = 'Format' })
end)

later(function()
  add({ 'https://github.com/f-person/auto-dark-mode.nvim' })
  require('auto-dark-mode').setup({
    update_interval = 1000,
    set_dark_mode = function() vim.o.background = 'dark'; vim.cmd.colorscheme('vulpes-reddishnovember-dark') end,
    set_light_mode = function() vim.o.background = 'light'; vim.cmd.colorscheme('vulpes-reddishnovember-light') end,
  })
end)
