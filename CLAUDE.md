# Claude Code Memory for ejfox's dotfiles

## Git Commit Rules

**DO NOT sign commits.** EJ signs his own commits manually with `git cs` (alias for `commit -S`). Claude-written commits should remain unsigned so EJ can distinguish them. Just use regular `git commit`.

## Critical Configuration Info

### Shell Configuration (.zshrc)
- **IMPORTANT**: Always ensure `/opt/homebrew/bin` is in PATH for nvim and other tools
- Main config is at `/Users/ejfox/.dotfiles/.zshrc` (symlinked from `~/.zshrc`)
- Secrets are stored in `~/.env` (NOT committed to git)
- Key backup locations:
  - `~/.zshrc.bak` (Sept 5, 2024) - most complete recent backup
  - `~/.zshrc.august-backup` (Sept 1, 2024)
  - `~/.deno/.shellRcBackups/.zshrc.bak` (Oct 12, 2024)

### Essential PATH components:
```bash
export PATH=$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH
```

## Things 3 Integration (Jan 24, 2026)

The MCP things tools (`mcp__things__*`) use `things-cli` which is **read-only**. To add tasks, use the Things URL scheme directly:

```bash
open "things:///add?title=TASK_TITLE&notes=NOTES&when=today"
```

### URL Parameters

| Parameter | Values | Notes |
|-----------|--------|-------|
| `title` | URL-encoded string | Task title |
| `notes` | URL-encoded string | Task notes/description |
| `when` | `today`, `tomorrow`, `evening`, `anytime`, `someday`, or `YYYY-MM-DD` | Scheduling |
| `deadline` | `YYYY-MM-DD` | Hard deadline (shows in Inbox until scheduled) |
| `tags` | comma-separated | e.g., `security,urgent` |
| `list` | project/area name | Target list |
| `heading` | heading name | Under a project heading |

### Scheduling Strategy

- **`when=today`** - Critical items that need attention now (shows in Today view)
- **`when=tomorrow`** - Follow-up/verification tasks
- **`deadline=YYYY-MM-DD`** - Hard deadlines (task stays in Inbox, shows deadline badge)
- **No `when` parameter** - Goes to Inbox for later triage

### Task Naming Conventions

Prefix tasks with action type for scanability:
- `FIX:` - Something broken that needs repair
- `VERIFY:` - Confirm a previous action worked
- `UPGRADE:` - Version/dependency updates
- `INVESTIGATE:` - Research/discovery tasks
- `CONSIDER:` - Optional improvements to evaluate
- `MONITOR:` - Ongoing watchlist items
- `OPTIONAL:` - Nice-to-have, low priority

### Example: Security Task Sequence

```bash
# Critical fix - do today
open "things:///add?title=FIX%3A%20Add%20DKIM%20records&notes=Steps%20here...&when=today"

# Verification - do tomorrow after DNS propagates
open "things:///add?title=VERIFY%3A%20DKIM%20working&notes=Check%20mail-tester.com&when=tomorrow"

# Future hardening - deadline but not scheduled (stays in Inbox with date badge)
open "things:///add?title=UPGRADE%3A%20DMARC%20to%20p%3Dreject&deadline=2026-02-07&tags=security"
```

### Reading Tasks (via MCP - read-only)

```bash
things-cli today      # Today's tasks
things-cli inbox      # Inbox tasks
things-cli projects   # List projects
```

### URL Encoding Tips

Common characters:
- `:` → `%3A`
- `/` → `%2F`
- `=` → `%3D`
- `&` → `%26`
- newline → `%0A`
- space → `%20`

Or use Python: `python3 -c "import urllib.parse; print(urllib.parse.quote('your text'))"`

## Wiki Systems (Dec 7, 2025)

EJ has TWO wiki/knowledge systems:

### 1. MediaWiki Archive (archive.ejfox.com)
**Status**: ✅ Claude has write access

**Credentials**: `~/.claude-secrets` (NOT in dotfiles, chmod 600)
```bash
source ~/.claude-secrets
# WIKI_USER, WIKI_PASS, WIKI_URL
```

**API Authentication Flow**:
```bash
# 1. Get login token
TOKEN=$(curl -s -c /tmp/wiki-cookies -b /tmp/wiki-cookies \
  "https://archive.ejfox.com/api.php?action=query&meta=tokens&type=login&format=json" | jq -r '.query.tokens.logintoken')

# 2. Login
source ~/.claude-secrets
curl -s -c /tmp/wiki-cookies -b /tmp/wiki-cookies -X POST "https://archive.ejfox.com/api.php" \
  --data-urlencode "action=login" --data-urlencode "lgname=${WIKI_USER}" \
  --data-urlencode "lgpassword=${WIKI_PASS}" --data-urlencode "lgtoken=${TOKEN}" \
  --data-urlencode "format=json"

# 3. Get CSRF token for editing
CSRF=$(curl -s -c /tmp/wiki-cookies -b /tmp/wiki-cookies \
  "https://archive.ejfox.com/api.php?action=query&meta=tokens&format=json" | jq -r '.query.tokens.csrftoken')

# 4. Edit a page
curl -s -c /tmp/wiki-cookies -b /tmp/wiki-cookies -X POST "https://archive.ejfox.com/api.php" \
  --data-urlencode "action=edit" --data-urlencode "title=PageName" \
  --data-urlencode "text=Page content here" --data-urlencode "summary=Edit summary" \
  --data-urlencode "token=${CSRF}" --data-urlencode "format=json"
```

**Quick read** (no auth needed):
```bash
curl -s "https://archive.ejfox.com/api.php?action=query&titles=Projects&prop=revisions&rvprop=content&format=json" | jq -r '.query.pages[].revisions[0]["*"]'
```

**Key pages**: Main_Page, Projects, Technical, Questions, Learning
**Claude's user page**: https://archive.ejfox.com/wiki/User:Claude

### 2. Obsidian Vault (local)
**Path**: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox`
**Aliases**: `o` (fzf browse), `obsidian` (cd to vault)
**MCP**: `obsidian-mcp` configured for direct read/write

### Critical aliases and functions:
- `commit` - Smart git commit with LLM integration
- `dev`, `yarni`, `c`, `showcase`, `newsketch` - Development shortcuts
- `scraps()` - Supabase query function
- `summarize_commits()` - Git history analysis
- `mermaid`, `mmd`, `ascii-mermaid` - mermaid-ascii tool aliases (installed in `~/bin/`)
- `send-mermaid <pane>` - Send mermaid diagram to tmux pane (WORKS!)
- `test-mermaid [pane]` - Quick test diagram to pane (defaults to 0:6.2)
- `quick-diagram <pane> [type]` - Send template diagram to pane
- `setup-diagram-listener <pane>` - Set up auto-refreshing diagram display
- `list-panes` - Show all available tmux panes

### AI-Powered Git Commits (Dec 7, 2025):
**Status**: ✅ ACTIVE - Custom ai-commit script with fzf + Claude Code CLI

**Location**: `~/.dotfiles/bin/ai-commit` (symlinked to `~/bin/ai-commit`)

**How to use**:
1. Stage files in lazygit (space to stage)
2. Hit **`a`** key (AI commit)
3. fzf shows 3 AI-generated conventional commit messages
4. See live diff preview on the right side
5. Select with arrows or fuzzy search, Enter to commit

**Architecture**:
```
User hits 'a' in lazygit
    ↓
ai-commit script gathers context:
    - git diff --cached (staged changes)
    - git branch --show-current (e.g., "feat/add-auth")
    - git log -5 --oneline (recent commit patterns)
    ↓
Sends to claude CLI with enhanced prompt
    ↓
Claude returns 3 conventional commit messages
    ↓
fzf launches with vulpes red theme:
    - Left: 3 commit options
    - Right: Full diff preview (60% width)
    - Fuzzy search enabled
    ↓
git commit -m "selected message"
```

**Lazygit config**: `~/.config/lazygit/config.yml`
```yaml
customCommands:
  - key: "a"
    context: "files"
    description: "🤖 AI commit (fzf + Claude)"
    subprocess: true
    command: 'MSG=$(ai-commit) && git commit -m "$MSG"'
```

**Context provided to Claude**:
- **Staged diff**: Only what's being committed (focused, no noise)
- **Branch name**: Helps infer scope (feat/user-auth → scope: "auth")
- **Recent commits**: Claude learns your commit style/patterns
- **File count**: For user feedback only

**Commit format**: Conventional Commits
```
<type>(<scope>): <subject>

Types: feat, fix, docs, style, refactor, perf, test, chore
Rules:
- Lowercase, imperative mood, no period at end
- Max 72 chars total
- Infer type from diff (new files = feat, fixes = fix)
- Infer scope from branch name or file paths
- Match style of recent commits
```

**fzf UI features**:
- Fuzzy search: Type "fix" to filter to fix commits
- Arrow keys: Navigate options
- Preview pane: See commit message + full diff side-by-side
- Ctrl-C: Cancel and return to lazygit
- Custom colors: Matches vulpes red aesthetic

**Example output**:
```
feat(auth): add user login functionality
fix(api): resolve null pointer in auth handler
chore(deps): update authentication dependencies
```

**Performance**:
- Speed: ~2-3 seconds for Claude API call
- Tokens: ~500-1000 per request (includes diff + context)
- Cost: ~$0.01-0.02 per commit (Claude Sonnet 4.5)
- Uses existing ANTHROPIC_API_KEY from ~/.env

**Customization points in script**:
- Line 63: Number of options ("exactly 3" → "exactly 5")
- Lines 44-63: Conventional commits template/rules
- Line 86: Preview size (`right:60%` → `right:70%`)
- Line 88: fzf color scheme (vulpes red theme)
- Lines 22-23: Additional context (files, commit depth)

**Error handling**:
- ✅ No staged changes → error message, exits
- ✅ Claude API failure → error message, exits
- ✅ User cancels fzf (Ctrl-C) → exits cleanly
- ✅ Empty Claude response → error message

**Why this approach**:
- No API key config needed (uses Claude Code CLI)
- No npm package dependencies or version conflicts
- Full control over prompt and UI
- Respects your existing workflow and aesthetics
- Tracked in dotfiles for easy portability

**Test example** (from real usage):
```bash
Branch: main
Staged: bin/ai-commit, .config/lazygit/config.yml

Generated:
1. chore(lazygit): switch theme to dark mode variant
2. feat(git): add ai-commit script with claude-powered message generation
3. feat(bin): add interactive ai-commit tool with fzf selection
```

### CIPHER Morning Ritual (Dec 7, 2025):
**Status**: ✅ ACTIVE - Futuristic life-guiding shell experience

**Location**: `~/.dotfiles/bin/morning-ritual` (symlinked to `~/bin/morning-ritual`)

**Trigger**: Runs once per day on first boot via `.startup.sh` integration

**What it does**:
CIPHER analyzes your ENTIRE reality and suggests 12 pomodoros RANKED BY PRIORITY. You pick your top 3 for the day using fzf multi-select.

**Architecture**:
```
.startup.sh runs on first boot
    ↓
Checks if already run today (/tmp/morning_ritual/last_run)
    ↓
Gather ALL context (this is HEAVY):
    - Things.app tasks (via AppleScript)
    - Calendar events (icalBuddy)
    - Recent git activity (all repos in ~/code, ~/projects, etc)
    - Command history patterns (last 200 commands)
    - Day/time/energy state
    - Obsidian week note (finds current week file)
    - 5 most recent Obsidian docs (first 2000 + last 2000 chars each)
    ↓
Send to claude CLI with CIPHER persona from .llm-persona.txt
    ↓
CIPHER returns 12 pomodoros RANKED BY PRIORITY with dry observations
    ↓
fzf launches with multi-select (TAB):
    - Left: 12 pomodoros (#01-#12) with CIPHER's WHY
    - Right: Full context preview (50 lines)
    - Header shows: "#1 is most urgent"
    ↓
User picks top 3 (or any number) via TAB + Enter
    ↓
Selected pomodoros added to Things inbox via AppleScript
    ↓
Mark as run today, exit
```

**CIPHER personality** (from `~/.dotfiles/.llm-persona.txt`):
- Terse, insightful, William Gibson meets Unix philosophy
- Dry wit with competence: "Your code works. How suspiciously efficient."
- Subtle absurdism, understated sarcasm, casually profound
- Brief observations, never more than 280 chars
- Geometric symbols: ◆ ◇ ○ ●

**Context gathered**:
1. **Things tasks**: Today's list + Anytime list (if today < 5 tasks, grabs top 10 from Anytime)
2. **Calendar**: When you have time (avoids meetings)
3. **Git activity**: What repos have momentum (7 day window)
4. **Command patterns**: What tools you've been using (nvim, git, docker, etc)
5. **GitHub activity** (via `gh` CLI):
   - Unread notifications (top 10)
   - PRs waiting for your review
   - Your open PRs and their status
   - Recent comments/activity on your PRs (last 24h)
6. **Day/time context**:
   - Energy state (morning-clarity, peak-focus, evening-reflection, etc)
   - **Day vibe**: WEEKEND (prioritize rest/creative) vs WEEKDAY (work mode)
   - Special handling: Sunday = rest day, Friday = wrap up gracefully, Monday = set momentum
7. **Obsidian week note**: Your weekly plan/reflections
8. **Recent Obsidian notes**: 5 most recent files edited in last 7 days (smart truncation)

**Example pomodoro suggestions** (showing top 6 of 12):
```
#01 finish turbo repo migration before context scatters ◆ chaos phase detected, 47 uncommitted files await coherence
#02 respond to supabase email before it becomes archaeological ◆ inbox archaeology intensifies, three days is the threshold
#03 write that thing about keyboard workflows you keep avoiding ◆ obsidian note has grown to 3847 chars, either publish or delete
#04 review pr for authentication refactor ◆ teammate blocked, your approval required
#05 update dependencies in vulpes-theme-lab ◆ 12 packages outdated, avoiding won't make them disappear
#06 outline next dataviz article ◆ momentum from recent commits suggests strike while iron hot
...6 more ranked by priority...
```

**fzf features**:
- 12 ranked options (#01 = most urgent/important)
- Multi-select with TAB (pick your top 3, or any number)
- Preview shows full context (Things, calendar, git, Obsidian, etc)
- Priority visible in listing (#01, #02, etc)
- Ctrl-C to reject CIPHER's wisdom entirely
- Vulpes red colorscheme
- CIPHER commentary: "You rejected CIPHER's wisdom. Interesting choice."

**Output**:
Selected pomodoros are added to Things inbox with today's date automatically.

**Performance**:
- Context gathering: ~2-3 seconds (git repo scanning is heaviest)
- Claude API call: ~3-5 seconds (HEAVY context, lots of tokens)
- Total: ~5-8 seconds from start to fzf display
- Token cost: ~2000-4000 tokens (Obsidian notes are big)
- Cost: ~$0.04-0.08 per morning ritual with Claude Sonnet 4.5

**Caching/State**:
- `/tmp/morning_ritual/last_run` - Date stamp of last run
- `/tmp/morning_ritual/last_context.txt` - Full context for debugging
- `/tmp/morning_ritual/last_raw_output.txt` - Raw CIPHER output
- Only runs once per day (checks date stamp)

**Manual usage**:
```bash
morning-ritual  # Force run even if already run today
rm /tmp/morning_ritual/last_run && morning-ritual  # Reset today's run
```

**Integration with .startup.sh**:
Added at line 357, runs after all other startup components:
```bash
if command -v morning-ritual &>/dev/null; then
  morning-ritual 2>&1 || true
fi
```

**Why this is next-level**:
- Analyzes your ACTUAL work context, not generic task lists
- **Prioritization AI**: 12 ranked options, #1 is most urgent (considers deadlines, momentum, energy, impact)
- **Weekend intelligence**: Knows it's Sunday and prioritizes rest/creative/🌞 tasks over work grind
- CIPHER personality makes it feel like a companion, not a tool
- Deep Obsidian integration (week notes + recent work)
- Git momentum detection (suggests continuing active projects)
- Command pattern analysis (knows what tools you've been in)
- **Anytime list integration**: Pulls from Anytime when today is light (<5 tasks)
- One-time-per-day keeps it special, not annoying
- Multi-select lets you pick what resonates (not forced to pick 3)
- Feeds directly into Things for execution
- Priority numbers stripped before adding to Things (clean task names)

**Weekend vs Weekday prioritization**:
- **Sunday/Saturday**: Prioritize 🌞 tasks (workout, journal, meditate, read, make/publish), creative projects, rest
- **Friday**: Wrap up work gracefully, transition to weekend mode
- **Monday**: Set momentum carefully, fresh week energy
- **Tue-Thu**: Work mode, balance urgency with sustainability

**Visual flow**:
```
Terminal boots → .startup.sh runs → Shows stats/calendar/oracle
                                          ↓
                      "◆ CIPHER awakens. Analyzing your reality..."
                                          ↓
                    Gathers Things, calendar, git, Obsidian, history
                                          ↓
                      "◆ CIPHER contemplates your trajectory..."
                                          ↓
                     Claude API call (3-5s with CIPHER persona)
                                          ↓
                "◆ CIPHER ranked 12 trajectories by priority. Pick your top 3:"
                                          ↓
                    fzf with 12 ranked pomodoros (#01-#12) + WHY
                                          ↓
                   TAB to multi-select top 3, Enter to accept
                                          ↓
                    "◆ Added to Things: [pomodoro title]"
                                          ↓
                  "◆ CIPHER has spoken. Your trajectory is set."
```

### Tmux Pane Communication:
**General pane operations**:
```bash
# List all panes with details
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} - #{pane_title} (#{pane_current_command})"

# Send commands to specific panes
tmux send-keys -t 0:6.2 "echo 'hello from another pane'" Enter
tmux send-keys -t 0:6.2 C-c  # Send Ctrl-C

# Send files/content to panes
tmux send-keys -t 0:6.2 "cat /path/to/file" Enter

# Set pane titles for easier targeting
tmux select-pane -t 0:6.2 -T "display-pane"
```

**Mermaid ASCII Diagram Magic** (ACTUALLY FUCKING WORKS):
```bash
# PROPER WORKFLOW - Use multiline syntax and -a flag:
echo "graph TD
A[Start] --> B[Process]
B --> C[End]
C --> D[Success]" | mermaid-ascii -a > /tmp/diagram.txt
tmux send-keys -t 0:6.2 "clear && cat /tmp/diagram.txt" Enter

# WRONG (doesn't work): echo "graph TD; A-->B; B-->C" | mermaid-ascii
# RIGHT (works): Multiline syntax + -a flag for ASCII-only

# Quick diagram function:
send-mermaid() {
    echo "graph TD
A[User Input] --> B[mermaid-ascii -a]
B --> C[ASCII Diagram]
C --> D[tmux send-keys]
D --> E[Visual Success]" | mermaid-ascii -a > /tmp/quick.txt
    tmux send-keys -t "$1" "clear && echo '🎯 MERMAID:' && cat /tmp/quick.txt && rm /tmp/quick.txt" Enter
}

# Set up a "listener" pane with file watcher
tmux send-keys -t 0:6.2 "watch -n 0.5 'cat /tmp/mermaid_display 2>/dev/null || echo \"📊 Ready for diagrams...\"'" Enter
# Then send: echo "graph TD..." | mermaid-ascii -a > /tmp/mermaid_display
```

**Critical mermaid-ascii rules**:
- ✅ Use multiline syntax (not semicolons)
- ✅ Always use `-a` flag for ASCII-only mode
- ✅ Test locally first: `echo "graph TD..." | mermaid-ascii -a`
- ❌ Don't use Unicode box chars (they get garbled)

**Available panes** (always check current state):
- Use `tmux list-panes -a` to find current active panes
- Display pane varies - ask user which pane to use or to create one
- Target format: `session:window.pane` (e.g., `0:6.2`, `main:1.1`)

### Security:
- Secrets moved to `~/.env` and sourced with `[ -f ~/.env ] && source ~/.env`
- Never commit API keys or tokens to git

## Common Issues:
1. **nvim not found**: Check if `/opt/homebrew/bin` is in PATH
2. **Missing aliases**: Verify config merged properly from backups
3. **Config loss**: Always check backup files before major changes

## Testing checklist:
- [ ] `which nvim` returns `/opt/homebrew/bin/nvim`
- [ ] `type dev` shows alias
- [ ] Environment variables load from `~/.env`
- [ ] P10k prompt loads correctly
- [ ] `mermaid-ascii --help` works
- [ ] `test-mermaid 0:6.2` sends working diagram

## Mermaid-ASCII + tmux Integration (Sept 28, 2025):
**Status**: ✅ WORKING - Real ASCII diagrams in tmux panes!

**Key lessons learned**:
1. **Syntax matters**: Use multiline format, NOT semicolons
   - ✅ `graph TD\nA --> B\nB --> C`
   - ❌ `graph TD; A-->B; B-->C`
2. **ASCII-only mode required**: Always use `-a` flag to avoid garbled output
3. **Terminal compatibility**: Unicode box chars get mangled, ASCII works
4. **Functions available**: `send-mermaid`, `test-mermaid`, `quick-diagram`, `setup-diagram-listener`

Last major restore: May 27, 2025 - Merged September backup with current config
Last feature addition: Sep 28, 2025 - mermaid-ascii tmux integration

## Tmux 2025 Modern Workflows (Nov 15, 2025):
**Status**: ✅ ACTIVE - Modern popup workflows for pane-based workflow

**Note**: User prefers pane-based workflow (not sessions/windows), so sessionizer removed.

### Popup Workflows (THE GOOD SHIT):
- `C-a g` → Lazygit popup in current directory (GAME CHANGER)
  - Floats over your panes, do git stuff, close it, back to work
  - No disruption to your carefully arranged panes
- `C-a K` → Yazi file manager popup
  - Quick file browsing without opening new panes
- `C-a S` → Scratch terminal toggle (persistent)
  - Floating terminal for quick commands/calculations
  - Toggle away with same key, session persists in background
  - Great for one-off API tests, jq parsing, quick scripts

### Pane Capture:
- `C-a C-y` → Yank entire pane (all scrollback) to clipboard
- `C-a M-y` → Yank last 200 lines to clipboard
  - No more manual selection for copying command output

### Helper Scripts:
- `~/.local/bin/tmux-scratch-toggle` - Toggle scratch terminal with persistence
- Tracked in `~/.dotfiles/bin/`

### Dependencies:
- `lazygit` (already installed) - Git TUI
- `yazi` (already installed) - File manager
- `fzf` (already installed) - Fuzzy finder

### Daily Workflow (Pane-Based):
- Multiple panes visible at once (editor, servers, logs, etc)
- `C-a g` → quick git operations without disrupting pane layout
- `C-a S` → scratch terminal for one-off commands
- `C-a C-y` → yank command output to paste elsewhere

**Why popup workflows work for pane users:**
- Don't create new panes/windows that mess up your layout
- Float over everything temporarily
- Quick toggle on/off
- Back to your panes exactly as you left them

**Commit**: 185fcad - feat(tmux): add 2025 modern workflows (sessionizer removed later)

## Neovim 0.11 Upgrade (Nov 16, 2025):
**Status**: ✅ UPGRADED - 0.10.4 → 0.11.5

**Major new features:**
- Built-in LSP auto-completion (opt-in)
- Async treesitter parsing (no more UI blocking on large files)
- Better terminal support (OSC 52 clipboard, kitty keyboard protocol)
- Virtual lines for diagnostics (multiple errors on same line)
- Shell prompt jumping with `[[` and `]]` in terminal buffers
- Improved cursor shape/blink in terminal

**Action required:**
- Open nvim and run `:Lazy sync` to update all plugins for 0.11 compatibility
- Run `:checkhealth` to verify everything works
- Run `:help news` to see full changelog

**Upgraded via:** `brew upgrade neovim`

## Essential Plugins for Daily Driver (Nov 16, 2025):
**Status**: ✅ INSTALLED - oil.nvim, vim-tmux-navigator, tmux-thumbs

### oil.nvim - Filesystem as a Buffer
**Location**: `~/.config/nvim/lua/plugins/oil.lua`

Edit your filesystem like any Vim buffer:
- `-` → Open parent directory (vim-vinegar style)
- `<CR>` → Open file/directory
- Delete a line → Delete file
- Edit a line → Rename file
- Create new line → Create new file
- `g.` → Toggle hidden files
- `<C-s>` → Open in vertical split
- `<C-h>` → Open in horizontal split

**Why it's better than file trees:**
- No separate UI, just buffers and motions
- Vim muscle memory applies to filesystem
- Fast and minimal

### vim-tmux-navigator - Seamless Navigation
**Location**: `~/.config/nvim/lua/plugins/vim-tmux-navigator.lua`

Single keybindings work across BOTH Nvim splits AND tmux panes:
- `Ctrl-h` → Move left (vim window or tmux pane)
- `Ctrl-j` → Move down (vim window or tmux pane)
- `Ctrl-k` → Move up (vim window or tmux pane)
- `Ctrl-l` → Move right (vim window or tmux pane)
- `Ctrl-\` → Previous split

**Perfect for pane-based workflow:**
- No mental overhead about "am I in vim or tmux?"
- Just move in any direction, it works
- Essential for multi-pane development

### tmux-thumbs - Vimium-Style Hints
**Location**: `~/.tmux.conf` (plugin: fcsonline/tmux-thumbs)

Hit `prefix + Space`, get letter hints on all visible text:
- Type letters to copy text to clipboard
- Uppercase hint = copy + paste
- Home row keys (asdfghjkl) for hints
- **Way faster than mouse selection or tmux copy mode**

**Replaced tmux-fingers** (Rust rewrite, much faster)

**Common use cases:**
- Copy URLs from terminal output
- Grab error messages
- Copy file paths from ls output
- Extract API tokens from logs

### Vue/Nuxt LSP Setup (Jan 26, 2026)
**Status**: ✅ CONFIGURED - Volar 2.0+ Hybrid Mode
**Location**: `~/.config/nvim/lua/plugins/vue-lsp.lua`

#### The Problem (Why gd/gr Never Worked)

Volar 2.0 (late 2024) completely changed the architecture:
- **Old way (Takeover Mode)**: Volar handled everything - TypeScript, HTML, CSS
- **New way (Hybrid Mode)**: Volar only handles HTML/CSS. TypeScript needs a separate server.

If you just enable LazyVim's Vue extra without additional config, `gd` returns 0 results because:
1. `vue_ls` (Volar) doesn't handle TypeScript anymore
2. `vtsls` doesn't know about `.vue` files by default
3. No one is handling TypeScript in your Vue SFCs

#### The Solution

**Architecture** (how it works now):
```
┌─────────────────────────────────────────────────────────────┐
│                     .vue file                                │
├─────────────────────────────────────────────────────────────┤
│  <template>  │  <script lang="ts">  │  <style>              │
│              │                       │                       │
│  vue_ls      │  vtsls + @vue/       │  vue_ls               │
│  (HTML)      │  typescript-plugin    │  (CSS)                │
│              │  (TypeScript)         │                       │
└─────────────────────────────────────────────────────────────┘
```

**Config** (`~/.config/nvim/lua/plugins/vue-lsp.lua`):
1. **vtsls filetypes include `vue`** - Critical! Without this, vtsls ignores .vue files
2. **@vue/typescript-plugin** - Gives vtsls Vue SFC awareness (script blocks, etc.)
3. **nuxt-goto.nvim** - Fixes Nuxt's auto-import `.d.ts` redirect issue

**Plugins installed**:
- `rushjs1/nuxt-goto.nvim` - Nuxt-specific gd fix

**Dependencies** (via Mason):
- `vue-language-server` (includes @vue/typescript-plugin)
- `vtsls` (TypeScript server)

#### Troubleshooting

**gd returns 0/0 results:**
1. Check LSPs are attached: `:lua print(vim.inspect(vim.lsp.get_clients({bufnr=0})))`
2. Should see both `vtsls` AND `vue_ls` attached
3. If only `copilot`, the config isn't loading

**gd goes to .d.ts file instead of source:**
- This is what `nuxt-goto.nvim` fixes
- Make sure `.nuxt` directory exists (`nuxt prepare` or `nuxt dev`)

**LSP not starting:**
```bash
# Verify mason packages
ls ~/.local/share/nvim/mason/packages/ | grep -E "vue|vtsls"

# Check vue-language-server works
~/.local/share/nvim/mason/bin/vue-language-server --version

# Check logs
:LspLog
```

#### Sources & References

- [Volar 2.0 Migration Guide](https://lsp-zero.netlify.app/blog/configure-volar-v2.html) - The definitive config guide
- [Vue Language Tools](https://github.com/vuejs/language-tools) - Official Vue LSP
- [nuxt-goto.nvim](https://github.com/rushjs1/nuxt-goto.nvim) - Nuxt gd fix
- [LazyVim Vue Extra](https://www.lazyvim.org/extras/lang/vue) - Base config we extend
- [mason-lspconfig#371](https://github.com/williamboman/mason-lspconfig.nvim/issues/371) - Volar 2 breaking change discussion
- [LazyVim#2363](https://github.com/LazyVim/LazyVim/discussions/2363) - gd stops working discussion

### nvim-dap - Debugging
**Location**: `~/.config/nvim/lua/plugins/nvim-dap.lua`

Full debugging for TypeScript/JavaScript/Vue:
- `<leader>db` → Toggle breakpoint
- `<leader>dc` → Start/continue debugging
- `<leader>di` → Step into
- `<leader>do` → Step over
- `<leader>dO` → Step out
- `<leader>dt` → Terminate
- `<leader>du` → Toggle debug UI
- `<leader>de` → Eval expression (normal/visual)

**Features:**
- Console output visible in bottom panel
- Variable scopes, call stack, watches in right panel
- Inline virtual text shows variable values
- Auto-opens UI when debugging starts
- No more console.log hell

### kulala.nvim - HTTP Client
**Location**: `~/.config/nvim/lua/plugins/kulala.lua`

Test APIs without leaving nvim:
- Create `.http` files with requests
- `<CR>` → Execute request under cursor
- `[r` / `]r` → Jump between requests
- `<leader>ri` → Inspect request
- `<leader>rc` → Copy as cURL

**Example .http file:**
```http
### Get user
GET https://api.example.com/users/1
Authorization: Bearer {{token}}

### Create user
POST https://api.example.com/users
Content-Type: application/json

{
  "name": "John Doe"
}
```

Better than Postman for quick API tests, keeps requests in version control.

### git-conflict.nvim - Merge Conflicts
**Location**: `~/.config/nvim/lua/plugins/minimal-git.lua`

Handle merge conflicts visually:
- `co` → Choose ours (current branch)
- `ct` → Choose theirs (incoming)
- `cb` → Choose both
- `c0` → Choose none
- `[x` / `]x` → Jump between conflicts

Green highlight = incoming, gray highlight = current.
Fast resolution without manual marker editing.

## Nvim + Sketchybar Major Updates (Nov 15, 2025):
**Status**: ✅ COMPLETE - Transparency, CIPHER coach, security cleanup

### Nvim Transparency (Ghostty Integration)
**Location**: `~/.config/nvim/colors/vulpes-reddishnovember-{dark,light}.lua`

Made editor background fully transparent to use Ghostty's transparent background:
- Set `Normal`, `NormalNC` backgrounds → `'none'`
- Set `SignColumn`, `FoldColumn`, `WinBar`, `TabLine` backgrounds → `'none'`
- Set diagnostic signs and virtual text backgrounds → `'none'`
- Applied to both dark and light colorscheme variants

**Restart nvim** or run `:colorscheme vulpes-reddishnovember-dark` to reload.

### Sketchybar CIPHER Coach
**Location**: `~/.config/sketchybar/plugins/next_event.sh`

Intelligent calendar event display with Things task integration:
- Shows next timed event with countdown ("in 15m", "at 3:00")
- Skips all-day events entirely
- Strips ANSI codes from icalBuddy output
- Uses LLM to format event titles with emoji

**CIPHER Mode** (when no events in next 4 hours):
- Reads today's tasks from Things via AppleScript
- Picks most joyful/appealing task and highlights it
- "Supportive coach, not taskmaster" tone
- Caches messages to avoid excessive API calls
- Updates only when: hour changes, tasks change, or completions change

**Styling**:
- 10pt font (smaller, subtle)
- Dark grey text (0xff666666)
- Update frequency: 60 seconds

**Config**: `~/.config/sketchybar/sketchybarrc` line 43-45

### Battery Fade Effect
**Location**: `~/.config/sketchybar/plugins/battery.sh`

Smooth gradient from black to red as battery drains:
- 20 minutes = black background (normal)
- Gradually increases red intensity as time decreases
- 0 minutes = full red alarm
- Formula: `RED_INTENSITY = 255 * (20 - MINS) / 20`

### Telescope Keybindings
**Location**: `~/.config/nvim/lua/plugins/minimal-telescope.lua`

Added custom mappings:
- `<C-v>` disabled (removed default behavior)
- `<C-_>` → `select_vertical` (open in vertical split)

### LSP Navigation Override
**Location**: `~/.config/nvim/lua/config/keymaps.lua`

Disabled snacks_picker extra for all LSP keybindings (had reliability issues):
- `gd` → `vim.lsp.buf.definition` (Goto Definition)
- `gr` → `vim.lsp.buf.references` (Goto References)
- `gI` → `vim.lsp.buf.implementation` (Goto Implementation)
- `gy` → `vim.lsp.buf.type_definition` (Goto Type Definition)
- `<leader>ss` → `vim.lsp.buf.document_symbol` (Document Symbols)
- `<leader>sS` → `vim.lsp.buf.workspace_symbol` (Workspace Symbols)
- `gai` → `vim.lsp.buf.incoming_calls` (Incoming Calls)
- `gao` → `vim.lsp.buf.outgoing_calls` (Outgoing Calls)

All now use native LSP protocol directly instead of snacks.nvim picker layer.

### Security Cleanup (CRITICAL)
**Date**: Nov 15, 2025

**9 API keys scrubbed from git history**:
1. Anthropic API key (sk-ant-...)
2. OpenRouter API key (sk-or-...) - exposed publicly, auto-disabled
3. OpenAI project key (sk-proj-...)
4. Twitter bot OAuth (4 tokens: consumer key/secret, access token/secret)
5. Twitter bearer token
6. Supabase anon key (JWT)

**145 files removed** from Library/ (Adobe, Sketch, VLC prefs, 8MB Unreal Engine binary)

**Secrets moved to ~/.env** (gitignored):
- .bash_profile cleaned of all hardcoded credentials
- Now sources ~/.env for secrets
- NEVER commit ~/.env

**Improved .gitignore**:
```gitignore
# Secrets and credentials
.env
.env.*
*.key
*.pem
claude.json

# macOS application state
Library/
*.app/

# Temporary files
*.swp
*~
```

**Action items**:
- ✅ All keys scrubbed from entire git history (119 commits rewritten)
- ✅ Force pushed cleaned history
- ⚠️ ROTATE ALL THOSE KEYS - they were publicly visible
- ⚠️ Check GitHub security alerts: https://github.com/ejfox/dotfiles/security

### LazyVim Config
**Disabled plugins**:
- Harpoon (not using this workflow) - `~/.config/nvim/lua/plugins/harpoon.lua` line 4

**Commit**: f25883c - chore: remove secrets from .bash_profile, improve .gitignore

## Vulpes Shader System (Nov 25, 2025):
**Status**: ✅ ACTIVE - Custom GLSL shaders for Ghostty with vulpes aesthetic

### Shader Stack (Order matters!)
**Location**: `~/.config/ghostty/shaders/`

Shaders stack in order (configured in `~/.config/ghostty/config`):
1. **cursor-blaze-vulpes.glsl** - Hot pink cursor trail (#ff268c)
   - Velocity-reactive: small moves = 0.32s, big jumps = 0.65s
   - Opacity scales: 45% (small) to 85% (big moves)
   - Colors: TRAIL_COLOR #ff268c, ACCENT #850045
   - Teleport detection: >25% screen = pane switch, no trail

2. **bloom-vulpes.glsl** - Red-selective glow effect
   - Only blooms red/pink pixels via `isWarmColor()` filter
   - Bloom output tinted red: `r *= 1.5, g *= 0.75, b *= 0.92`
   - Intensity: 0.38 (tuned sweet spot)
   - LUM_THRESHOLD: 0.14, RED_DOMINANCE: 0.18

3. **tft-subtle.glsl** - LCD subpixel effect
   - Resolution: 3.0, Strength: 0.20

### Bloom-Friendly Design Rules
When bloom is active, avoid bright saturated colors for UI elements:
- **Bad**: Bright pink/red selections → blooms into unreadable mess
- **Good**: Darker background + white text + bold = readable with bloom

Applied to:
- nvim Visual selection: `#6b1a3d` bg + white text
- nvim IncSearch/CurSearch: `#5c0030` bg + white text
- nvim Directory: muted pink `#c490a8` (no harsh bloom)
- nvim Functions/methods: white (stand out from red theme)
- tmux mode-style: `#8a0050` bg + white text

### Reload Shaders
`Cmd+Shift+,` in Ghostty to reload config/shaders

### Dependencies
Base shaders from: https://github.com/hackr-sh/ghostty-shaders

**Commit**: 83e330a - feat(ghostty): vulpes shader system with red-selective bloom

## nvim-ufo Code Folding (Jan 26, 2026)
**Status**: ✅ CONFIGURED
**Location**: `~/.config/nvim/lua/plugins/nvim-ufo.lua`

Better code folding using treesitter with indent fallback. Native vim folding commands work, plus extras.

### Commands

| Key | Action |
|-----|--------|
| `zo` | **o**pen fold under cursor |
| `zc` | **c**lose fold under cursor |
| `za` | toggle fold (open↔close) |
| `zR` | open all folds |
| `zM` | close all folds |
| `zK` | peek inside fold (nvim-ufo bonus) |
| `zj` | jump to next fold |
| `zk` | jump to prev fold |

**Mnemonic**: `z` looks like a folded paper. Then **o**pen, **c**lose, **a**lternate.

### Configuration

```lua
opts = {
  -- treesitter first, indent fallback (good for Vue mixed content)
  provider_selector = function(bufnr, filetype, buftype)
    return { "treesitter", "indent" }
  end,
}
```

### Sources
- [nvim-ufo GitHub](https://github.com/kevinhwang91/nvim-ufo)
- [LazyVim folding discussion](https://github.com/LazyVim/LazyVim/discussions/1572)

## mini.animate for nvim (Nov 25, 2025):
**Location**: `~/.config/nvim/lua/plugins/mini-animate.lua`

Subtle animations without distraction:
- **Cursor**: 80ms cubic easing (smooth jump between positions)
- **Resize**: 60ms cubic (window resize feels snappy)
- **Open/Close**: 60ms cubic (window transitions)
- **Scroll**: DISABLED (too distracting for daily use)

```lua
local timing_fast = animate.gen_timing.cubic({ duration = 60, unit = "total" })
local timing_cursor = animate.gen_timing.cubic({ duration = 80, unit = "total" })
```

## Usage Logging System (Jan 24, 2026):
**Status**: ✅ ACTIVE - Tracks shell/nvim/tmux activity for pattern analysis

### Quick Commands
```bash
usage-summary          # Today's stats
usage-summary 2025-01-20  # Specific day
usage-analyze          # Pattern analysis (last 7 days)
usage-analyze 30       # Last 30 days
```

### Log Location
```
~/.local/share/usage-logs/
  shell/YYYY-MM-DD.jsonl
  nvim/YYYY-MM-DD.jsonl
  tmux/YYYY-MM-DD.jsonl
```

### What's Captured

**Shell**: `cmd_start/end` (command, cwd, exit code, duration), `cd` (from/to), `session_start/end`

**Nvim**: `file_open/save/close` (path, filetype, lines), `mode_exit` (mode + duration), `command` (ex commands), `search` (pattern), `yank`, `lsp_attach`, `diagnostics`, `keys` (batched keystrokes)

**Tmux**: `window_select/new/rename`, `pane_select/split/exit` (id, window, cmd, path), `mode_change` (copy-mode)

### Config Files
| Component | Location |
|-----------|----------|
| Shell hooks | `~/.dotfiles/lib/shell-usage-logging.zsh` |
| Nvim plugin | `~/.config/nvim/lua/plugins/usage-logging.lua` |
| Tmux hooks | `~/.dotfiles/lib/tmux-usage-logging.conf` |
| Scripts | `~/.dotfiles/bin/usage-log`, `usage-summary`, `usage-analyze` |

### Analysis Use Cases
After 1+ week of data, Claude can analyze for:
- **Alias candidates**: Most frequent shell commands
- **Hot files**: Files opened 5+ times → harpoon/quick-access
- **Workspace scripts**: Directory/pane patterns you recreate
- **Keybinding gaps**: Repeated key sequences → macro candidates
- **Mode balance**: Insert vs normal time (editing style)
- **Slow commands**: Commands taking >2s → optimization targets

### Format
JSON lines - one event per line, ISO 8601 timestamps. Easy to parse with `jq`, visualize with d3, or create embeddings.

**Full docs**: `~/Desktop/USAGE-LOGGING.md`