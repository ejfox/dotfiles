# Claude Code Memory for ejfox's dotfiles

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