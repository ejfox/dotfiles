-- usage-logging.lua - Log nvim activity for analysis
-- Writes JSON lines to ~/.local/share/usage-logs/nvim/YYYY-MM-DD.jsonl

local log_dir = vim.fn.expand("~/.local/share/usage-logs/nvim")
local last_mode = "n"
local mode_start = os.time()
local keypress_buffer = {}
local keypress_flush_timer = nil

-- Ensure log directory exists
vim.fn.mkdir(log_dir, "p")

local function get_log_file()
  return log_dir .. "/" .. os.date("%Y-%m-%d") .. ".jsonl"
end

local function escape_json(s)
  if type(s) ~= "string" then return tostring(s) end
  return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
end

local function log_event(evt, data)
  vim.schedule(function()
    local entry = {
      string.format('"ts":"%s"', os.date("!%Y-%m-%dT%H:%M:%SZ")),
      '"src":"nvim"',
      string.format('"evt":"%s"', evt),
    }

    for k, v in pairs(data or {}) do
      table.insert(entry, string.format('"%s":"%s"', k, escape_json(v)))
    end

    local line = "{" .. table.concat(entry, ",") .. "}\n"
    local f = io.open(get_log_file(), "a")
    if f then
      f:write(line)
      f:close()
    end
  end)
end

-- File events
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype or ""
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    log_event("file_open", {
      file = ev.file,
      filetype = ft,
      lines = lines,
      cwd = vim.fn.getcwd(),
    })
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function(ev)
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    log_event("file_save", {
      file = ev.file,
      lines = lines,
    })
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(ev)
    if ev.file and ev.file ~= "" then
      log_event("file_close", { file = ev.file })
    end
  end,
})

-- Mode tracking (with duration)
vim.api.nvim_create_autocmd("ModeChanged", {
  callback = function()
    local new_mode = vim.fn.mode()
    local now = os.time()
    local duration = now - mode_start

    if duration > 0 and last_mode ~= new_mode then
      log_event("mode_exit", {
        mode = last_mode,
        duration = duration,
      })
    end

    last_mode = new_mode
    mode_start = now
  end,
})

-- Command execution
vim.api.nvim_create_autocmd("CmdlineLeave", {
  callback = function()
    local cmd = vim.fn.getcmdline()
    local cmdtype = vim.fn.getcmdtype()
    if cmd and cmd ~= "" and cmdtype == ":" then
      log_event("command", { cmd = cmd })
    end
  end,
})

-- Search patterns
vim.api.nvim_create_autocmd("CmdlineLeave", {
  callback = function()
    local pattern = vim.fn.getcmdline()
    local cmdtype = vim.fn.getcmdtype()
    if pattern and pattern ~= "" and (cmdtype == "/" or cmdtype == "?") then
      log_event("search", { pattern = pattern, direction = cmdtype })
    end
  end,
})

-- Window/split events - DISABLED (too noisy, fires for every popup/float)
-- vim.api.nvim_create_autocmd("WinNew", {
--   callback = function()
--     log_event("window_new", { wins = #vim.api.nvim_list_wins() })
--   end,
-- })
-- vim.api.nvim_create_autocmd("WinClosed", {
--   callback = function()
--     log_event("window_close", { wins = #vim.api.nvim_list_wins() })
--   end,
-- })

-- Tab events
vim.api.nvim_create_autocmd("TabNew", {
  callback = function()
    log_event("tab_new", { tabs = #vim.api.nvim_list_tabpages() })
  end,
})

-- LSP events
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then
      log_event("lsp_attach", { client = client.name, file = ev.file or "" })
    end
  end,
})

-- Terminal events
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    log_event("terminal_open", {})
  end,
})

-- Yank events
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local event = vim.v.event
    log_event("yank", {
      operator = event.operator,
      regtype = event.regtype,
      lines = #event.regcontents,
    })
  end,
})

-- Diagnostics (throttled - only on change)
local last_diag_count = 0
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    local count = #vim.diagnostic.get()
    if count ~= last_diag_count then
      log_event("diagnostics", {
        count = count,
        errors = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR }),
        warnings = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.WARN }),
      })
      last_diag_count = count
    end
  end,
})

-- Session start/end
log_event("session_start", {
  pid = vim.fn.getpid(),
  cwd = vim.fn.getcwd(),
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    log_event("session_end", { pid = vim.fn.getpid() })
  end,
})

-- Key sequence logging (batched every 2 seconds)
local function flush_keypresses()
  if #keypress_buffer > 0 then
    log_event("keys", { seq = table.concat(keypress_buffer, "") })
    keypress_buffer = {}
  end
end

vim.on_key(function(key)
  local char = vim.fn.keytrans(key)
  -- Skip special keys
  if char and char ~= "" and not char:match("^<.*>$") then
    table.insert(keypress_buffer, char)

    if #keypress_buffer >= 50 then
      flush_keypresses()
    elseif not keypress_flush_timer then
      keypress_flush_timer = vim.defer_fn(function()
        flush_keypresses()
        keypress_flush_timer = nil
      end, 2000)
    end
  end
end)

-- Return empty table so lazy.nvim doesn't complain
return {}
