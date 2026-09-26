-- ============================================================================
-- AI: autocomplete-style only (no chat)
-- ============================================================================
-- Ghost text: LazyVim ai.copilot-native extra -> nvim 0.12's built-in
--   vim.lsp.inline_completion + copilot-language-server (replaced copilot.lua).
-- Next Edit Suggestions: LazyVim ai.sidekick extra. Copilot predicts the
--   *next* edit elsewhere in the file; <Tab> jumps to it / applies it.
--
--   <Tab>       accept ghost text / jump+apply next edit (insert + normal)
--   <C-Right>   accept one word        <C-l>  accept rest of line
--   <M-]>/<M-[> cycle suggestions      <leader>uN  toggle next-edit
-- ============================================================================

-- WHY: 0.12's inline completion only accepts whole suggestions. These ports of
-- copilot.lua's accept_word/accept_line insert just the next chunk at the
-- cursor; copilot then re-suggests the remainder as you keep typing.
local function accept_partial(patterns, fallback)
  return function()
    local accepted = vim.lsp.inline_completion.get({
      on_accept = function(item)
        local text = type(item.insert_text) == "string" and item.insert_text or item.insert_text.value
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        row = row - 1
        local typed = ""
        if item.range and item.range.start_row == row and item.range.start_col <= col then
          typed = vim.api.nvim_buf_get_text(0, row, item.range.start_col, row, col, {})[1]
        end
        -- Can't line the suggestion up with what's typed: accept it whole.
        if text:sub(1, #typed) ~= typed then return item end
        local rest = text:sub(#typed + 1)
        local chunk
        for _, pat in ipairs(patterns) do
          chunk = chunk or rest:match(pat)
        end
        local lines = vim.split(chunk or rest, "\n")
        vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
        local end_col = (#lines == 1 and col or 0) + #lines[#lines]
        vim.api.nvim_win_set_cursor(0, { row + #lines, end_col })
        return nil -- we applied it ourselves
      end,
    })
    if not accepted then return fallback and vim.keycode(fallback) or "" end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      {
        "<C-Right>",
        -- leading punctuation + next word (".reduce"), else next non-space run
        accept_partial({ "^%s*[^%w_%s]*[%w_]+", "^%s*%S+" }, "<C-Right>"),
        mode = "i",
        expr = true,
        desc = "Accept AI word",
      },
      {
        "<C-l>",
        accept_partial({ "^\n?[^\n]*" }), -- no fallback: insert-mode <C-l> would type ^L
        mode = "i",
        expr = true,
        desc = "Accept AI line",
      },
    },
  },

  -- Keep sidekick to next-edit suggestions only: turn off its AI-CLI/chat keys.
  {
    "folke/sidekick.nvim",
    -- WHY: upstream spec only lazy-loads on keys, and LazyVim relies on its
    -- lualine component to load it early — our custom statusline replaces that,
    -- so NES would never start until the first normal-mode <Tab>.
    event = "VeryLazy",
    keys = {
      { "<c-.>", false, mode = { "n", "t", "i", "x" } },
      { "<leader>a", false, mode = { "n", "v" } },
      { "<leader>aa", false },
      { "<leader>as", false },
      { "<leader>ad", false },
      { "<leader>at", false, mode = { "x", "n" } },
      { "<leader>af", false },
      { "<leader>av", false, mode = { "x" } },
      { "<leader>ap", false, mode = { "n", "x" } },
    },
  },
}
