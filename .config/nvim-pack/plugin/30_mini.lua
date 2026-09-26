-- mini.nvim modules: one plugin standing in for snacks, which-key, flash,
-- nvim-surround, gitsigns/mini.diff, telescope/snacks picker, lualine,
-- nvim-notify, mini.pairs/ai/hipatterns.
local now, later = Config.now, Config.later
local map = vim.keymap.set

-- ── Startup-critical ────────────────────────────────────────────────────────
now(function()
  require('mini.icons').setup()
  -- WHY: oil.nvim (and others) ask for nvim-web-devicons; mini.icons answers.
  later(MiniIcons.mock_nvim_web_devicons)
  later(MiniIcons.tweak_lsp_kind)
end)

now(function()
  require('mini.notify').setup({
    window = { config = { border = 'none' }, max_width_share = 0.35 },
    lsp_progress = { enable = false }, -- quiet environment
  })
  vim.notify = MiniNotify.make_notify({ INFO = { duration = 2500 } })
  map('n', '<leader>n', MiniNotify.show_history, { desc = 'Notification history' })
end)

now(function()
  require('mini.statusline').setup({
    -- Minimal, like the main config: file, flags, AI marker, position.
    content = {
      active = function()
        local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
        local git = MiniStatusline.section_git({ trunc_width = 60 })
        local diag = MiniStatusline.section_diagnostics({ trunc_width = 75, icon = '' })
        local ai = #vim.lsp.get_clients({ name = 'copilot', bufnr = 0 }) > 0 and 'AI' or ''
        return MiniStatusline.combine_groups({
          { hl = mode_hl, strings = { mode } },
          { hl = 'MiniStatuslineFilename', strings = { '%f %m' } },
          '%=',
          { hl = 'MiniStatuslineDevinfo', strings = { git, diag, ai } },
          { hl = mode_hl, strings = { '%l:%c' } },
        })
      end,
    },
  })
end)

-- ── After first draw ───────────────────────────────────────────────────────
later(function() require('mini.extra').setup() end)
later(function() require('mini.bufremove').setup() end)
later(function() require('mini.bracketed').setup() end) -- ]b ]d ]q ]x ...
later(function() require('mini.pairs').setup({ modes = { command = true } }) end)
later(function() require('mini.indentscope').setup({ symbol = '│', draw = { animation = require('mini.indentscope').gen_animation.none() } }) end)

later(function()
  local ai = require('mini.ai')
  ai.setup({
    custom_textobjects = {
      F = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
      c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
    },
  })
end)

-- Surround with nvim-surround / vim-surround keys (from :h MiniSurround)
later(function()
  require('mini.surround').setup({
    mappings = {
      add = 'ys', delete = 'ds', replace = 'cs',
      find = '', find_left = '', highlight = '', update_n_lines = '',
      suffix_last = '', suffix_next = '',
    },
    search_method = 'cover_or_next',
  })
  vim.keymap.del('x', 'ys')
  map('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true, desc = 'Surround selection' })
  map('n', 'yss', 'ys_', { remap = true, desc = 'Surround line' })
end)

-- Hex colors + TODO/FIXME highlighting (was the mini-hipatterns extra)
later(function()
  local hi = require('mini.hipatterns')
  hi.setup({
    highlighters = {
      fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
      hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
      todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
      note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
      hex_color = hi.gen_highlighter.hex_color(),
    },
  })
end)

-- Jump anywhere: `s` + 2 chars, like flash (was flash.nvim)
later(function()
  require('mini.jump2d').setup({
    spotter = require('mini.jump2d').gen_spotter.pattern('[^%s%p]+'),
    view = { dim = true, n_steps_ahead = 2 },
    mappings = { start_jumping = '' },
  })
  map({ 'n', 'x', 'o' }, 's', function() MiniJump2d.start(MiniJump2d.builtin_opts.single_character) end, { desc = 'Jump' })
end)

-- Git: signs in the gutter + hunk ops (was gitsigns/mini.diff + git-conflict)
later(function()
  require('mini.git').setup()
  require('mini.diff').setup({ view = { style = 'sign', signs = { add = '▎', change = '▎', delete = '' } } })
  map('n', '<leader>go', MiniDiff.toggle_overlay, { desc = 'Toggle diff overlay' })
  map({ 'n', 'x' }, '<leader>gs', function() return MiniGit.show_at_cursor() end, { desc = 'Git show at cursor' })
end)

-- Picker (was snacks picker). Keys match LazyVim's so muscle memory carries.
later(function()
  require('mini.pick').setup({ window = { config = { border = 'none' } } })
  vim.ui.select = MiniPick.ui_select
  local P, E = MiniPick.builtin, MiniExtra.pickers
  map('n', '<leader><space>', P.files, { desc = 'Find files' })
  map('n', '<leader>ff', P.files, { desc = 'Find files' })
  map('n', '<leader>/', P.grep_live, { desc = 'Grep (live)' })
  map('n', '<leader>sg', P.grep_live, { desc = 'Grep (live)' })
  map('n', '<leader>sw', function() P.grep({ pattern = vim.fn.expand('<cword>') }) end, { desc = 'Grep word' })
  map('n', '<leader>fr', E.oldfiles, { desc = 'Recent files' })
  map('n', '<leader>,', P.buffers, { desc = 'Buffers' })
  map('n', '<leader>fb', P.buffers, { desc = 'Buffers' })
  map('n', '<leader>sh', P.help, { desc = 'Help' })
  map('n', '<leader>sk', E.keymaps, { desc = 'Keymaps' })
  map('n', '<leader>sd', E.diagnostic, { desc = 'Diagnostics' })
  map('n', '<leader>ss', function() E.lsp({ scope = 'document_symbol' }) end, { desc = 'Document symbols' })
  map('n', '<leader>gc', E.git_commits, { desc = 'Git commits' })
  map('n', '<leader>gh', E.git_hunks, { desc = 'Git hunks' })
  map('n', "<leader>s'", E.marks, { desc = 'Marks' })
  map('n', '<leader>sr', P.resume, { desc = 'Resume picker' })
end)

-- Key hints (was which-key)
later(function()
  local clue = require('mini.clue')
  clue.setup({
    window = { delay = 400, config = { width = 'auto', border = 'none' } },
    triggers = {
      { mode = 'n', keys = '<Leader>' }, { mode = 'x', keys = '<Leader>' },
      { mode = 'n', keys = 'g' }, { mode = 'x', keys = 'g' },
      { mode = 'n', keys = '[' }, { mode = 'n', keys = ']' },
      { mode = 'n', keys = 'z' }, { mode = 'x', keys = 'z' },
      { mode = 'n', keys = '<C-w>' },
      { mode = 'n', keys = "'" }, { mode = 'n', keys = '`' },
      { mode = 'n', keys = '"' }, { mode = 'x', keys = '"' },
      { mode = 'i', keys = '<C-r>' }, { mode = 'c', keys = '<C-r>' },
    },
    clues = {
      { mode = 'n', keys = '<Leader>b', desc = '+buffer' },
      { mode = 'n', keys = '<Leader>c', desc = '+code' },
      { mode = 'n', keys = '<Leader>f', desc = '+file' },
      { mode = 'n', keys = '<Leader>g', desc = '+git' },
      { mode = 'n', keys = '<Leader>s', desc = '+search' },
      { mode = 'n', keys = '<Leader>u', desc = '+ui' },
      { mode = 'x', keys = '<Leader>y', desc = '+yank w/ path' },
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers(),
      clue.gen_clues.square_brackets(),
      clue.gen_clues.windows(),
      clue.gen_clues.z(),
    },
  })
end)
