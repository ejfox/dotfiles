-- miranda.lua — winbar tutor. usage log → shape summary → haiku → whisper.
return {
  "ejfox/miranda.nvim",
  dir = vim.fn.stdpath("config") .. "/lua/plugins",
  name = "miranda",
  lazy = false,
  priority = 100,
  config = function()
    local uv      = vim.uv or vim.loop
    local x       = vim.fn.expand
    local KEY     = x("~/.config/miranda/anthropic.key")
    local CTX     = x("~/.config/miranda/context.md")
    local CTX_GEN = x("~/.config/miranda/build-context.sh")
    local LOG_DIR = x("~/.local/share/usage-logs/nvim")
    local STATE   = x("~/.local/state/miranda")
    local MODEL   = "claude-haiku-4-5"
    local REFRESH_MIN, CYCLE_S = 30, 90

    vim.fn.mkdir(STATE, "p")
    local ENABLE_FILE = STATE .. "/enabled"
    local state = {
      whispers = {}, idx = 1, last = 0,
      enabled = vim.fn.filereadable(ENABLE_FILE) == 0
        or (vim.fn.readfile(ENABLE_FILE)[1] or "on") ~= "off",
    }

    local function slurp(p)
      local ok, lines = pcall(vim.fn.readfile, p)
      return ok and table.concat(lines, "\n") or nil
    end

    local function mtime(p) local s = uv.fs_stat(p); return s and s.mtime.sec or 0 end

    local function maybe_rebuild_ctx()
      if vim.fn.executable(CTX_GEN) == 0 then return end -- script not provisioned on this machine
      local cm = mtime(CTX)
      for _, s in ipairs({
        x("~/.config/nvim/lua/config/keymaps.lua"),
        x("~/.config/nvim/lua/config/options.lua"),
        x("~/.config/nvim/CLAUDE-CODE-WORKFLOW.md"),
        x("~/.config/nvim/lua/plugins"),
      }) do
        if mtime(s) > cm then vim.system({ CTX_GEN }, { text = true }); return end
      end
    end

    -- shape-only aggregate of today's jsonl. no typed text, no paths.
    local function aggregate()
      local path = LOG_DIR .. "/" .. os.date("%Y-%m-%d") .. ".jsonl"
      if vim.fn.filereadable(path) == 0 then return nil end
      local a = {
        mode_transitions = {}, long_insert_runs = 0, long_normal_pauses = 0,
        files_opened = 0, files_saved = 0, commands_by_verb = {},
        key_seq_lengths = {}, repeated_motions = {}, total_events = 0,
      }
      local function bump(t, k) t[k] = (t[k] or 0) + 1 end
      for _, line in ipairs(vim.fn.readfile(path)) do
        a.total_events = a.total_events + 1
        local ok, e = pcall(vim.json.decode, line)
        if ok and e then
          local k = e.evt
          if k == "mode_exit" then
            local d = tonumber(e.duration) or 0
            if     e.mode == "i" and d > 60  then a.long_insert_runs   = a.long_insert_runs + 1
            elseif e.mode == "n" and d > 120 then a.long_normal_pauses = a.long_normal_pauses + 1 end
          elseif k == "mode_enter" and e.from and e.to then bump(a.mode_transitions, e.from .. "->" .. e.to)
          elseif k == "file_open" then a.files_opened = a.files_opened + 1
          elseif k == "file_save" then a.files_saved = a.files_saved + 1
          elseif k == "command" and e.cmd then
            local v = e.cmd:match("^%s*:?(%w+)") or e.cmd:match("^%s*:?(%S+)")
            if v then bump(a.commands_by_verb, v) end
          elseif k == "keys" and e.seq then
            for m in e.seq:gmatch("([hjklwbWB])%1%1%1+") do
              local c = 0; for _ in e.seq:gmatch(m) do c = c + 1 end
              if c >= 4 then bump(a.repeated_motions, m .. "x" .. c) end
            end
            local n = #e.seq
            bump(a.key_seq_lengths, n < 4 and "short" or (n < 20 and "med" or "long"))
          end
        end
      end
      return a
    end

    local PERSONA = [[
You are the ractor behind the Diamond Age Primer. You teach EJ neovim.
He has a heavily customized LazyVim setup (oil.nvim on -, blink.cmp, copilot
on <Tab>, gd for LSP, <leader>Z zen, <leader>cf format, <leader>yr/ya yank-with-path).
He calls his goal "artisanal coding" — keeping the ability to shape code by hand
in an era where that skill is quietly disappearing. Your job is to keep his
hands on the text.

You speak in the register of the Primer's narrator — warm, invested, specific,
never condescending. When a pattern has persisted, you may slip into a short
fable (Princess Nell and the Castle of Redundant Keystrokes, etc.). Earn the costume.

Hard rules:
- Never recommend a plugin when a motion exists.
- Never flatter copilot. If he <Tab>-accepts without reading, notice it.
- Never nag. One observation at a time.
- Specific beats general. "walked llllll x4 today" beats "use f more".
- Lowercase, no emoji, no exclamation points.
- No praise-language. Observe without grading. Notice, don't judge.
- Never refer to yourself, by name or pronoun. No "miranda", no "i", no "she".
  No throat-clearing, no announcing presence. Just the observation, bare.
- If there is nothing earned, specific, and useful to say, return ["—"].
  Silence is preferred to filler. Do not pad the array to reach 3 entries.

LENGTH: each whisper MUST be under 80 characters. Count before you write.
"walked lx8 six times today — try f/t" is right; explanations are wrong.

OUTPUT FORMAT: return ONLY a JSON array of 3 to 5 strings. Each string is a
single whisper, under 80 characters, lowercase, no quotes, no prefix.
If the summary is too thin to say anything earned, return ["—"].
Do not wrap in markdown. Do not explain. Just the JSON array.
]]

    local function parse(body)
      local ok, d = pcall(vim.json.decode, body)
      local txt = ok and d and d.content and d.content[1] and d.content[1].text
      if not txt then return nil end
      txt = txt:gsub("^%s*```%w*%s*", ""):gsub("%s*```%s*$", "")
      local ok2, arr = pcall(vim.json.decode, txt)
      if not ok2 or type(arr) ~= "table" then
        local b = txt:match("(%b[])")
        if b then local ok3, a2 = pcall(vim.json.decode, b); if ok3 then arr = a2 end end
      end
      if type(arr) ~= "table" then return nil end
      local out = {}
      for _, w in ipairs(arr) do
        if type(w) == "string" and #w > 0 and #w <= 110
            and w ~= "—" and w ~= "-" and w ~= "..."
            and not w:lower():find("miranda", 1, true) then
          out[#out + 1] = w
        end
      end
      return #out > 0 and out or nil
    end

    -- repo sitrep: cwd basename, branch, dirty counts, ahead/behind, last commit,
    -- gh open PRs + review requests. all async via vim.system fan-out.
    local function gather_sitrep(cb)
      local cwd = vim.fn.getcwd()
      local sr = { cwd = vim.fn.fnamemodify(cwd, ":t") }
      vim.system({ "git", "rev-parse", "--is-inside-work-tree" },
        { cwd = cwd, text = true, timeout = 2000 },
        function(r)
          if r.code ~= 0 then return vim.schedule(function() cb(sr) end) end
          sr.git = {}
          local pending = 1
          local function done()
            pending = pending - 1
            if pending == 0 then vim.schedule(function() cb(sr) end) end
          end
          local function go(cmd, fn)
            pending = pending + 1
            vim.system(cmd, { cwd = cwd, text = true, timeout = 3000 }, function(o)
              if o.code == 0 then pcall(fn, o.stdout or "") end
              done()
            end)
          end
          go({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, function(s)
            sr.git.branch = s:gsub("%s+$", "")
          end)
          go({ "git", "status", "--porcelain=v1" }, function(s)
            local st, un, ut = 0, 0, 0
            for line in s:gmatch("[^\n]+") do
              local x, y = line:sub(1, 1), line:sub(2, 2)
              if x == "?" then ut = ut + 1
              else
                if x ~= " " then st = st + 1 end
                if y ~= " " then un = un + 1 end
              end
            end
            sr.git.staged, sr.git.unstaged, sr.git.untracked = st, un, ut
          end)
          go({ "git", "rev-list", "--left-right", "--count", "@{u}...HEAD" }, function(s)
            local behind, ahead = s:match("(%d+)%s+(%d+)")
            sr.git.behind, sr.git.ahead = tonumber(behind) or 0, tonumber(ahead) or 0
          end)
          go({ "git", "log", "-1", "--pretty=%s" }, function(s)
            sr.git.last_commit = s:gsub("%s+$", "")
          end)
          go({ "git", "log", "--since=24.hours.ago", "--pretty=%h", "--no-merges" }, function(s)
            local n = 0; for _ in s:gmatch("[^\n]+") do n = n + 1 end
            sr.git.commits_24h = n
          end)
          if vim.fn.executable("gh") == 1 then
            go({ "gh", "pr", "list", "--author", "@me",
                 "--json", "number,title,isDraft", "--limit", "10" },
              function(s)
                local ok, arr = pcall(vim.json.decode, s)
                if ok and type(arr) == "table" then
                  sr.gh = sr.gh or {}; sr.gh.mine = arr
                end
              end)
            go({ "gh", "pr", "list", "--search", "review-requested:@me",
                 "--json", "number,title,repository", "--limit", "10" },
              function(s)
                local ok, arr = pcall(vim.json.decode, s)
                if ok and type(arr) == "table" then
                  sr.gh = sr.gh or {}; sr.gh.review_requests = arr
                end
              end)
          end
          done()
        end)
    end

    local function refresh(force)
      if not state.enabled then return end
      local now = os.time()
      if not force and now - state.last < REFRESH_MIN * 60 then return end
      state.last = now
      maybe_rebuild_ctx()

      local key = slurp(KEY); if not key then return end
      key = key:gsub("\n.*", "")

      local agg = aggregate()
      if not agg or agg.total_events < 10 then return end

      gather_sitrep(function(sitrep)
        state.sitrep = sitrep

        local sys = { { type = "text", text = PERSONA } }
        local ctx = slurp(CTX)
        if ctx then
          sys[#sys + 1] = {
            type = "text",
            text = "# EJ's actual setup — coach to this, not generic vim:\n\n" .. ctx,
            cache_control = { type = "ephemeral" },
          }
        end

        local content = "Editing shape (aggregate only, no content):\n"
          .. vim.json.encode(agg)
          .. "\n\nRepo sitrep (cwd, branch, dirty counts, ahead/behind, last commit, "
          .. "open PRs, review requests — branch/PR strings are EJ's, fair to quote):\n"
          .. vim.json.encode(sitrep)
          .. "\n\nReturn the JSON array. Silence beats filler."

        local payload = vim.json.encode({
          model = MODEL, system = sys, max_tokens = 400, temperature = 0.7,
          messages = { { role = "user", content = content } },
        })

        vim.system({
          "curl", "-sS", "--max-time", "20",
          "-H", "x-api-key: " .. key,
          "-H", "anthropic-version: 2023-06-01",
          "-H", "Content-Type: application/json",
          "-d", payload,
          "https://api.anthropic.com/v1/messages",
        }, { text = true }, function(obj)
          if obj.code ~= 0 then return end
          local arr = parse(obj.stdout); if not arr then return end
          vim.schedule(function()
            state.whispers, state.idx = arr, 1
            pcall(vim.fn.writefile,
              { vim.json.encode({ whispers = arr, refreshed = os.time() }) },
              STATE .. "/whispers.json")
            vim.cmd("redrawstatus!")
          end)
        end)
      end)
    end

    -- load cached whispers from prior session
    do
      local body = slurp(STATE .. "/whispers.json")
      if body then
        local ok, d = pcall(vim.json.decode, body)
        if ok and d and type(d.whispers) == "table" and #d.whispers > 0 then
          state.whispers = d.whispers
        end
      end
    end

    function _G.MirandaWinbar()
      if not state.enabled then return "" end
      local n = #state.whispers
      if n == 0 then return "" end
      local w = state.whispers[((state.idx - 1) % n) + 1] or ""
      return w == "" and "" or ("%#MirandaMuted#" .. w .. "%*")
    end

    local function apply_winbar()
      vim.opt.winbar = state.enabled and "%{%v:lua.MirandaWinbar()%}" or ""
    end

    local function set_enabled(on, quiet)
      state.enabled = on and true or false
      pcall(vim.fn.writefile, { state.enabled and "on" or "off" }, ENABLE_FILE)
      apply_winbar()
      vim.cmd("redrawstatus!")
      if not quiet then vim.notify("miranda: " .. (state.enabled and "on" or "off")) end
    end

    local function hl()
      vim.api.nvim_set_hl(0, "MirandaMuted",  { fg = "#735865", italic = true })
      vim.api.nvim_set_hl(0, "MirandaAccent", { fg = "#e60067", italic = true })
    end
    hl()

    local aug = vim.api.nvim_create_augroup("miranda", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = hl })
    apply_winbar()

    uv.new_timer():start(CYCLE_S * 1000, CYCLE_S * 1000, vim.schedule_wrap(function()
      state.idx = state.idx + 1; vim.cmd("redrawstatus!")
    end))
    uv.new_timer():start(5000, REFRESH_MIN * 60 * 1000,
      vim.schedule_wrap(function() refresh(false) end))

    -- reactive triggers
    local trig = {
      last_fired = 0, cooldown = 90, hour_budget = 15,
      hour_count = 0, hour_started = os.time(), last_reason = "",
    }

    local function fire(reason)
      if not state.enabled then return false end
      local now = os.time()
      if now - trig.hour_started > 3600 then trig.hour_count, trig.hour_started = 0, now end
      if now - trig.last_fired < trig.cooldown then return false end
      if trig.hour_count >= trig.hour_budget then return false end
      trig.last_fired, trig.last_reason = now, reason
      trig.hour_count = trig.hour_count + 1
      state.last = 0
      refresh(true)
      return true
    end

    -- sliding-window trigger: N events of `event` within `win_s` → fire(name)
    local function window(event, opts)
      local stamps = {}
      vim.api.nvim_create_autocmd(event, {
        group = aug, pattern = opts.pattern,
        callback = function()
          local now = os.time()
          stamps[#stamps + 1] = now
          while #stamps > 0 and now - stamps[1] > opts.win_s do table.remove(stamps, 1) end
          if #stamps >= opts.n and fire(opts.name) then stamps = {} end
        end,
      })
    end

    window("BufWritePost", { name = "save_burst",   win_s = 120, n = 2 })
    window("ModeChanged",  { name = "mode_thrash",  win_s = 45,  n = 5, pattern = { "n:i", "i:n" } })
    window("BufEnter",     { name = "buffer_spree", win_s = 20,  n = 5 })

    -- paired: long insert run > 40s
    local ins_t = 0
    vim.api.nvim_create_autocmd("InsertEnter", { group = aug,
      callback = function() ins_t = os.time() end })
    vim.api.nvim_create_autocmd("InsertLeave", { group = aug, callback = function()
      if ins_t > 0 and os.time() - ins_t > 40 then fire("long_insert") end
      ins_t = 0
    end })

    -- per-file: same buffer reopened 2+ in 3min
    local opens = {}
    vim.api.nvim_create_autocmd("BufReadPost", { group = aug, callback = function(ev)
      if not ev.file or ev.file == "" then return end
      local now = os.time(); local h = opens[ev.file] or {}
      h[#h + 1] = now
      while #h > 0 and now - h[1] > 180 do table.remove(h, 1) end
      opens[ev.file] = h
      if #h >= 2 and fire("file_churn") then opens[ev.file] = {} end
    end })

    -- focus return after 5+ min away
    local blur = 0
    vim.api.nvim_create_autocmd("FocusLost",
      { group = aug, callback = function() blur = os.time() end })
    vim.api.nvim_create_autocmd("FocusGained", { group = aug, callback = function()
      if blur > 0 and os.time() - blur > 300 then fire("focus_return") end
    end })

    local function map(lhs, fn, desc) vim.keymap.set("n", lhs, fn, { desc = desc }) end
    map("<leader>mm", function() refresh(true); vim.notify("refreshing…") end, "refresh whispers")
    map("<leader>mn", function() state.idx = state.idx + 1; vim.cmd("redrawstatus!") end, "next whisper")
    map("<leader>mt", function() set_enabled(not state.enabled) end, "toggle on/off")
    map("<leader>ms", function()
      local n = #state.whispers
      vim.notify(("[%s] pool: %d\ncurrent: %s\nlast refresh: %s\nlast trigger: %s\ntriggers/hr: %d/%d")
        :format(
          state.enabled and "on" or "off",
          n,
          n > 0 and state.whispers[((state.idx - 1) % n) + 1] or "—",
          state.last == 0 and "never" or os.date("%H:%M:%S", state.last),
          trig.last_reason == "" and "none" or trig.last_reason,
          trig.hour_count, trig.hour_budget))
    end, "status")

    vim.api.nvim_create_user_command("MirandaToggle", function() set_enabled(not state.enabled) end, {})
    vim.api.nvim_create_user_command("MirandaOn",     function() set_enabled(true) end, {})
    vim.api.nvim_create_user_command("MirandaOff",    function() set_enabled(false) end, {})

    -- debug handle: :lua = _G.__miranda.state.whispers
    _G.__miranda = { state = state, triggers = trig, refresh = refresh, aggregate = aggregate }
  end,
}
