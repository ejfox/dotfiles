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