-- ============================================================================
-- STRUDEL: Live code music from Neovim via strudel.cc
-- Syncs buffer ↔ browser, controls playback, evals code
-- File types: .str, .std → detected as javascript for treesitter highlighting
-- Note: lazy=false because setup() registers the filetype autocmd (see gh#5)
-- WHY buffer-local keys: global <leader>sl/su/sq shadowed LazyVim's location
-- list / undo history / quickfix, and <leader>st lost to Todo. Strudel files
-- are plain javascript filetype, so scope by file extension instead.
-- ============================================================================

return {
  "gruvw/strudel.nvim",
  build = "npm ci",
  lazy = false,
  config = function(_, opts)
    require("strudel").setup(opts)
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      group = vim.api.nvim_create_augroup("StrudelKeys", { clear = true }),
      pattern = { "*.str", "*.std" },
      callback = function(ev)
        local function map(lhs, cmd, desc)
          vim.keymap.set("n", lhs, cmd, { buffer = ev.buf, desc = desc })
        end
        map("<leader>sl", "<cmd>StrudelLaunch<cr>", "Strudel Launch")
        map("<leader>st", "<cmd>StrudelToggle<cr>", "Strudel Toggle play/stop")
        map("<leader>su", "<cmd>StrudelUpdate<cr>", "Strudel Update (eval)")
        map("<leader>sq", "<cmd>StrudelQuit<cr>", "Strudel Quit")
      end,
    })
  end,
  opts = {},
}
