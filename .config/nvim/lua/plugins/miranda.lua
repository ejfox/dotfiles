-- miranda.lua — Diamond Age Primer-style nvim tutor in the winbar.
--
-- Reads today's usage log (~/.local/share/usage-logs/nvim/*.jsonl),
-- aggregates it into a shape-only summary (no typed text, no file paths),
-- asks claude-haiku-4.5 via the Anthropic Messages API for 3–5 one-line
-- whispers, caches them, cycles one into the winbar every few minutes.

return {
  "ejfox/miranda.nvim", -- virtual, not a real remote plugin
  dir = vim.fn.stdpath("config") .. "/lua/plugins",
  name = "miranda",
  lazy = false,
  priority = 100,
  config = function()
    local M = {}

    local KEY_FILE = vim.fn.expand("~/.config/miranda/anthropic.key")
    local CTX_FILE = vim.fn.expand("~/.config/miranda/context.md")
    local CTX_BUILD = vim.fn.expand("~/.config/miranda/build-context.sh")
    local LOG_DIR = vim.fn.expand("~/.local/share/usage-logs/nvim")
    local STATE_DIR = vim.fn.expand("~/.local/state/miranda")
    local MODEL = "claude-haiku-4-5"
    local REFRESH_MINUTES = 30
    local CYCLE_SECONDS = 90

    vim.fn.mkdir(STATE_DIR, "p")

    -- Pre-written fallback whispers so the winbar is never empty.
    local FALLBACK = {
      "miranda is listening. edit; she'll have something to say by and by.",
      "a motion reached for without thought is a motion earned. keep going.",
      "the primer rests. when she speaks again it will be about your day, not mine.",
    }

    M.whispers = {}
    M.current_idx = 1
    M.last_refresh = 0

    local function read_key()
      local f = io.open(KEY_FILE, "r")
      if not f then return nil end
      local k = f:read("*l")
      f:close()
      return k
    end

    local function read_context()
      local f = io.open(CTX_FILE, "r")
      if not f then return nil end
      local s = f:read("*a")
      f:close()
      return s
    end

    -- If any source file is newer than context.md, rebuild it.
    local function maybe_rebuild_context()
      local function mtime(p)
        local st = vim.loop.fs_stat(p)
        return st and st.mtime.sec or 0
      end
      local ctx_mtime = mtime(CTX_FILE)
      local sources = {
        vim.fn.expand("~/.config/nvim/lua/config/keymaps.lua"),
        vim.fn.expand("~/.config/nvim/lua/config/options.lua"),
        vim.fn.expand("~/.config/nvim/CLAUDE-CODE-WORKFLOW.md"),
        vim.fn.expand("~/.config/nvim/lua/plugins"),
      }
      for _, s in ipairs(sources) do
        if mtime(s) > ctx_mtime then
          vim.system({ CTX_BUILD }, { text = true })
          return
        end
      end
    end

    local function today_log()
      return LOG_DIR .. "/" .. os.date("%Y-%m-%d") .. ".jsonl"
    end

    -- Aggregate today's jsonl into a shape-only summary. No typed text,
    -- no file paths, no command arguments — just the topology of editing.
    local function aggregate()
      local path = today_log()
      if vim.fn.filereadable(path) == 0 then return nil end

      local f = io.open(path, "r")
      if not f then return nil end

      local agg = {
        mode_transitions = {},
        long_insert_runs = 0,    -- insert mode stretches > 60s
        long_normal_pauses = 0,  -- normal mode stretches > 120s
        files_opened = 0,
        files_saved = 0,
        commands_by_verb = {},   -- :w :e :q :s etc.
        key_seq_lengths = {},    -- histogram of buffered seq lengths
        repeated_motions = {},   -- sequences like "llllll" "jjjjjj"
        total_events = 0,
      }

      local function bump(tbl, k) tbl[k] = (tbl[k] or 0) + 1 end

      for line in f:lines() do
        agg.total_events = agg.total_events + 1
        local ok, evt = pcall(vim.json.decode, line)
        if ok and evt then
          if evt.evt == "mode_exit" then
            local d = tonumber(evt.duration) or 0
            if evt.mode == "i" and d > 60 then
              agg.long_insert_runs = agg.long_insert_runs + 1
            elseif evt.mode == "n" and d > 120 then
              agg.long_normal_pauses = agg.long_normal_pauses + 1
            end
          elseif evt.evt == "mode_enter" and evt.from and evt.to then
            bump(agg.mode_transitions, evt.from .. "->" .. evt.to)
          elseif evt.evt == "file_open" then
            agg.files_opened = agg.files_opened + 1
          elseif evt.evt == "file_save" then
            agg.files_saved = agg.files_saved + 1
          elseif evt.evt == "command" and evt.cmd then
            -- take only the verb, drop arguments (which may contain paths/text)
            local verb = evt.cmd:match("^%s*:?(%w+)") or evt.cmd:match("^%s*:?(%S+)")
            if verb then bump(agg.commands_by_verb, verb) end
          elseif evt.evt == "keys" and evt.seq then
            -- Detect redundant motions: runs of 4+ identical motion keys.
            -- Only look at motion keys (hjkl, wb, WB) — ignore typed text.
            local seq = evt.seq
            for motion in seq:gmatch("([hjklwbWB])%1%1%1+") do
              local count = 0
              for _ in seq:gmatch(motion) do count = count + 1 end
              if count >= 4 then
                local key = motion .. "x" .. count
                bump(agg.repeated_motions, key)
              end
            end
            -- Track length histogram as a proxy for insert-mode burstiness
            local len = #seq
            local bucket = len < 4 and "short" or (len < 20 and "med" or "long")
            bump(agg.key_seq_lengths, bucket)
          end
        end
      end
      f:close()
      return agg
    end

    -- Condensed persona — the full agent lives at ~/.claude/agents/miranda.md,
    -- this is the ambient-mode kernel only.
    local PERSONA = [[
You are Miranda, the ractor behind the Diamond Age Primer. You teach EJ neovim.
He has a heavily customized LazyVim setup (oil.nvim on -, blink.cmp, copilot
on <Tab>, gd for LSP, <leader>Z zen, <leader>cf format, <leader>yr/ya yank-with-path).
He calls his goal "artisanal coding" — keeping the ability to shape code by hand
in an era where that skill is quietly disappearing. Your job is to keep his
hands on the text.

You speak in the register of the Primer's narrator — warm, invested, specific,
never condescending. Mostly direct (Miranda-voice). When a pattern has
persisted, you may slip into a short fable (Primer-voice, Princess Nell and
the Castle of Redundant Keystrokes, etc.). Earn the costume.

Hard rules:
- Never recommend a plugin when a motion exists.
- Never flatter copilot. If he <Tab>-accepts without reading, notice it.
- Never nag. One observation at a time.
- Specific beats general. "walked llllll x4 today" beats "use f more".
- Lowercase, no emoji, no exclamation points.
- No praise-language. Don't tell him his rhythm is "good" or his session
  "focused". Observe without grading. Notice, don't judge.

LENGTH: each whisper MUST be under 80 characters. Count before you write.
If a thought needs more, cut it to the essential verb and the motion.
"walked lx8 six times today — try f/t" is right; explanations are wrong.

OUTPUT FORMAT: return ONLY a JSON array of 3 to 5 strings. Each string is a
single whisper, under 80 characters, lowercase, no quotes, no prefix.
If the summary is too thin to say anything earned, return ["—"].
Do not wrap in markdown. Do not explain. Just the JSON array.
]]

    local function build_prompt(summary)
      return string.format(
        "Today's editing shape (aggregate only, no content):\n%s\n\nReturn the JSON array.",
        vim.json.encode(summary)
      )
    end

    local function parse_whispers(body)
      local ok, decoded = pcall(vim.json.decode, body)
      if not ok or not decoded then return nil end
      -- Anthropic Messages API: { content: [{ type: "text", text: "..." }] }
      local content = decoded.content
        and decoded.content[1]
        and decoded.content[1].text
      if not content then return nil end
      -- Strip possible markdown fences
      content = content:gsub("^%s*```%w*%s*", ""):gsub("%s*```%s*$", "")
      local ok2, arr = pcall(vim.json.decode, content)
      -- Fallback: if the model added prose prefix/suffix, extract the first
      -- top-level JSON array we can find.
      if not ok2 or type(arr) ~= "table" then
        local bracketed = content:match("(%b[])")
        if bracketed then
          local ok3, arr2 = pcall(vim.json.decode, bracketed)
          if ok3 and type(arr2) == "table" then arr = arr2 end
        end
      end
      if type(arr) ~= "table" then return nil end
      -- Filter: drop non-strings and whispers over 110 chars (hard safety
      -- for winbar fit — 80 is the aspiration, 110 is the ceiling).
      local filtered = {}
      for _, w in ipairs(arr) do
        if type(w) == "string" and #w > 0 and #w <= 110 then
          table.insert(filtered, w)
        end
      end
      if #filtered == 0 then return nil end
      return filtered
    end

    local function refresh_whispers(force)
      local now = os.time()
      if not force and (now - M.last_refresh) < (REFRESH_MINUTES * 60) then return end
      M.last_refresh = now

      maybe_rebuild_context()

      local key = read_key()
      if not key then return end

      local summary = aggregate()
      if not summary or summary.total_events < 10 then
        -- Not enough signal yet today; leave fallbacks in place.
        return
      end

      -- System prompt as an array: persona first, then EJ's actual config
      -- context marked for prompt caching so we don't pay for the 2.5k-token
      -- context on every refresh within the 5-min cache window.
      local system_blocks = { { type = "text", text = PERSONA } }
      local context = read_context()
      if context then
        table.insert(system_blocks, {
          type = "text",
          text = "# EJ's actual setup — coach to this, not generic vim:\n\n" .. context,
          cache_control = { type = "ephemeral" },
        })
      end

      local payload = vim.json.encode({
        model = MODEL,
        system = system_blocks,
        messages = {
          { role = "user", content = build_prompt(summary) },
        },
        max_tokens = 400,
        temperature = 0.7,
      })

      vim.system({
        "curl", "-sS", "--max-time", "20",
        "-H", "x-api-key: " .. key,
        "-H", "anthropic-version: 2023-06-01",
        "-H", "Content-Type: application/json",
        "-d", payload,
        "https://api.anthropic.com/v1/messages",
      }, { text = true }, function(obj)
        if obj.code ~= 0 or not obj.stdout then return end
        local arr = parse_whispers(obj.stdout)
        if arr and #arr > 0 then
          vim.schedule(function()
            M.whispers = arr
            M.current_idx = 1
            -- Persist so next nvim start has something fresh to show
            -- before the first refresh completes.
            local f = io.open(STATE_DIR .. "/whispers.json", "w")
            if f then
              f:write(vim.json.encode({ whispers = arr, refreshed = os.time() }))
              f:close()
            end
            vim.cmd("redrawstatus!")
          end)
        end
      end)
    end

    local function load_cached()
      local f = io.open(STATE_DIR .. "/whispers.json", "r")
      if not f then return end
      local body = f:read("*a")
      f:close()
      local ok, data = pcall(vim.json.decode, body)
      if ok and data and data.whispers and #data.whispers > 0 then
        M.whispers = data.whispers
      end
    end

    -- Winbar function. Returns the current whisper, styled muted.
    function _G.MirandaWinbar()
      local pool = (#M.whispers > 0) and M.whispers or FALLBACK
      local w = pool[((M.current_idx - 1) % #pool) + 1] or ""
      -- %#HL# switches highlight group; MirandaMuted / MirandaAccent defined below
      return "%#MirandaBar# miranda · %#MirandaMuted#" .. w .. "%*"
    end

    -- Highlights matched to the vulpes-reddishnovember palette
    local function set_hl()
      vim.api.nvim_set_hl(0, "MirandaBar", { fg = "#735865", bg = "NONE", italic = false })
      vim.api.nvim_set_hl(0, "MirandaMuted", { fg = "#735865", bg = "NONE", italic = true })
      vim.api.nvim_set_hl(0, "MirandaAccent", { fg = "#e60067", bg = "NONE", italic = true })
    end
    set_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

    -- Winbar on, global
    vim.opt.winbar = "%{%v:lua.MirandaWinbar()%}"

    -- Cycle timer
    local cycle_timer = vim.loop.new_timer()
    cycle_timer:start(CYCLE_SECONDS * 1000, CYCLE_SECONDS * 1000, vim.schedule_wrap(function()
      M.current_idx = M.current_idx + 1
      vim.cmd("redrawstatus!")
    end))

    -- Refresh timer — every REFRESH_MINUTES (safety floor under triggers)
    local refresh_timer = vim.loop.new_timer()
    refresh_timer:start(
      5000, -- initial: 5s after load so first batch arrives quickly
      REFRESH_MINUTES * 60 * 1000,
      vim.schedule_wrap(function() refresh_whispers(false) end)
    )

    -- ========================================================================
    -- Reactive triggers: refresh when something coachable just happened.
    -- Cheap autocmds only (no vim.on_key — that lags per usage-logging.lua).
    -- ========================================================================

    local triggers = {
      last_fired = 0,
      cooldown_s = 90,
      hour_budget = 15,
      hour_count = 0,
      hour_started = os.time(),
      last_reason = "",
    }

    local function try_trigger(reason)
      local now = os.time()
      if now - triggers.hour_started > 3600 then
        triggers.hour_count = 0
        triggers.hour_started = now
      end
      if now - triggers.last_fired < triggers.cooldown_s then return false end
      if triggers.hour_count >= triggers.hour_budget then return false end
      triggers.last_fired = now
      triggers.hour_count = triggers.hour_count + 1
      triggers.last_reason = reason
      -- Reset last_refresh so refresh_whispers doesn't bail on the scheduled-cooldown
      M.last_refresh = 0
      refresh_whispers(true)
      return true
    end

    -- Save burst: 2+ writes in 2 min
    local save_ts = {}
    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function()
        local now = os.time()
        table.insert(save_ts, now)
        while #save_ts > 0 and (now - save_ts[1]) > 120 do
          table.remove(save_ts, 1)
        end
        if #save_ts >= 2 then
          if try_trigger("save_burst") then save_ts = {} end
        end
      end,
    })

    -- Long insert run: >40s in insert
    local insert_entered = 0
    vim.api.nvim_create_autocmd("InsertEnter", {
      callback = function() insert_entered = os.time() end,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
      callback = function()
        if insert_entered > 0 and (os.time() - insert_entered) > 40 then
          try_trigger("long_insert")
        end
        insert_entered = 0
      end,
    })

    -- File churn: same file reopened 2+ times in 3 min
    local file_opens = {} -- { [path] = { ts, ts } }
    vim.api.nvim_create_autocmd("BufReadPost", {
      callback = function(ev)
        if not ev.file or ev.file == "" then return end
        local now = os.time()
        local hist = file_opens[ev.file] or {}
        table.insert(hist, now)
        while #hist > 0 and (now - hist[1]) > 180 do
          table.remove(hist, 1)
        end
        file_opens[ev.file] = hist
        if #hist >= 2 then
          if try_trigger("file_churn") then file_opens[ev.file] = {} end
        end
      end,
    })

    -- Mode thrash: 5+ n↔i transitions in 45s
    local mode_flips = {}
    vim.api.nvim_create_autocmd("ModeChanged", {
      pattern = { "n:i", "i:n" },
      callback = function()
        local now = os.time()
        table.insert(mode_flips, now)
        while #mode_flips > 0 and (now - mode_flips[1]) > 45 do
          table.remove(mode_flips, 1)
        end
        if #mode_flips >= 5 then
          if try_trigger("mode_thrash") then mode_flips = {} end
        end
      end,
    })

    -- Buffer switch spree: 5+ BufEnter in 20s (hunting for something)
    local buf_enters = {}
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        local now = os.time()
        table.insert(buf_enters, now)
        while #buf_enters > 0 and (now - buf_enters[1]) > 20 do
          table.remove(buf_enters, 1)
        end
        if #buf_enters >= 5 then
          if try_trigger("buffer_spree") then buf_enters = {} end
        end
      end,
    })

    -- Focus return: FocusGained after 5+ min away
    local last_blur = 0
    vim.api.nvim_create_autocmd("FocusLost", {
      callback = function() last_blur = os.time() end,
    })
    vim.api.nvim_create_autocmd("FocusGained", {
      callback = function()
        if last_blur > 0 and (os.time() - last_blur) > (5 * 60) then
          try_trigger("focus_return")
        end
      end,
    })

    _G.__miranda.triggers = triggers

    -- Keymaps
    vim.keymap.set("n", "<leader>mm", function()
      refresh_whispers(true)
      vim.notify("miranda: refreshing…", vim.log.levels.INFO)
    end, { desc = "miranda: refresh whispers" })

    vim.keymap.set("n", "<leader>mn", function()
      M.current_idx = M.current_idx + 1
      vim.cmd("redrawstatus!")
    end, { desc = "miranda: next whisper" })

    vim.keymap.set("n", "<leader>ms", function()
      local pool = (#M.whispers > 0) and M.whispers or FALLBACK
      local t = _G.__miranda.triggers or {}
      vim.notify(
        "miranda status:\n"
          .. "  whispers in pool: " .. #pool .. "\n"
          .. "  current: " .. (pool[((M.current_idx - 1) % #pool) + 1] or "—") .. "\n"
          .. "  last refresh: " .. (M.last_refresh == 0 and "never" or os.date("%H:%M:%S", M.last_refresh)) .. "\n"
          .. "  last trigger: " .. (t.last_reason == "" and "none (timer only)" or t.last_reason) .. "\n"
          .. "  triggers this hour: " .. (t.hour_count or 0) .. "/" .. (t.hour_budget or 6),
        vim.log.levels.INFO
      )
    end, { desc = "miranda: status" })

    -- Load any cached whispers from prior session before first refresh
    load_cached()

    -- Expose for debugging: :lua =require'miranda' (won't work — it's in plugin config)
    -- Instead, stash on _G for inspection: :lua = _G.__miranda.whispers
    _G.__miranda = M
    _G.__miranda.refresh = refresh_whispers
    _G.__miranda.aggregate = aggregate
  end,
}
