-- nvim-ufo: Better code folding
-- https://github.com/kevinhwang91/nvim-ufo
return {
  "kevinhwang91/nvim-ufo",
  dependencies = { "kevinhwang91/promise-async" },
  event = "BufRead",
  keys = {
    { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
    { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
    { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
  },
  opts = {
    -- Use treesitter first, fall back to indent (good for Vue mixed content)
    provider_selector = function(bufnr, filetype, buftype)
      return { "treesitter", "indent" }
    end,
    -- Transparent foldtext: first line renders with full treesitter
    -- highlighting so you can actually read folded code at a glance
    fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local suffix = ("  %d lines "):format(endLnum - lnum)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0
      for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(newVirtText, chunk)
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          local hlGroup = chunk[2]
          table.insert(newVirtText, { chunkText, hlGroup })
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end
      table.insert(newVirtText, { suffix, "Comment" })
      return newVirtText
    end,
  },
  init = function()
    -- Required ufo settings
    vim.o.foldcolumn = "0" -- Hide fold column (snacks handles fold indicators)
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    -- Transparent foldtext: renders first line with original syntax highlighting
    vim.o.foldtext = ""
    vim.opt.fillchars:append({ fold = " " })
  end,
}
