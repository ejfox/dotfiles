# Tmux Configuration

Minimal tmux setup with vim-style navigation and plugin integrations.

## Installation

```bash
# Tmux is configured via ~/.dotfiles/.tmux.conf
# TPM (Tmux Plugin Manager) auto-installs plugins

# After cloning, install plugins:
tmux source ~/.tmux.conf
# Press: prefix + I (capital I) to install all plugins
```

## Plugins Installed

### Core Plugins
- **tpm** - Plugin manager
- **tmux-sensible** - Sensible defaults
- **tmux-yank** - Copy to system clipboard (prefix + y in copy mode)
- **tmux-resurrect** - Session save/restore
- **tmux-continuum** - Auto-save sessions (restore on startup)

### New Additions
- **tmux-fzf** - Fuzzy finder for sessions, panes, windows
  - `prefix + s` - Find and switch sessions
  - `prefix + w` - Find windows
  - `prefix + p` - Find panes
- **tmux-fingers** - Vimium-style copy/search
  - `prefix + f` - Activate (press 'f' after prefix key)
  - Type hint letters to copy/jump to visible text
  - Yellow hint boxes appear on hover
  - `<Enter>` to copy, `<C-c>` to cancel

## Core Keybindings

### Navigation
| Keybinding | Action |
|-----------|--------|
| `Ctrl-a` | Prefix key |
| `h/j/k/l` | Navigate panes (vim-style) |
| `<` / `>` | Swap panes |
| `Alt-1` through `Alt-9` | Direct pane select |
| `Alt-h` / `Alt-l` | Previous/next window |
| `Shift-Left` / `Shift-Right` | Previous/next window (alt) |

### Window & Pane Management
| Keybinding | Action |
|-----------|--------|
| `prefix-c` | New window (in current path) |
| `prefix--` | Split vertically (in current path) |
| `prefix-_` | Split horizontally (in current path) |
| `prefix-Shift-H/J/K/L` | Resize pane (repeat enabled) |
| `prefix-C-c` | New session |
| `prefix-C-f` | Find/switch session |

### Session Management
| Keybinding | Action |
|-----------|--------|
| `prefix-d` | Detach from session |
| `prefix-s` | List/switch sessions (tmux-fzf) |
| Sessions auto-save and restore on startup (tmux-continuum) |

### Copy Mode
| Keybinding | Action |
|-----------|--------|
| `prefix-[` | Enter copy mode |
| `Space` | Start selection |
| `Enter` | Copy selection |
| `prefix-y` | Copy visible text to clipboard (tmux-yank) |
| `q` | Exit copy mode |

### Special
| Keybinding | Action |
|-----------|--------|
| `prefix-Z` | Toggle zen mode (dims window, hides status bar) |
| `prefix-f` | Activate tmux-fingers (copy hint-based text) |

## Tmux-fingers Workflow

```
1. Press: prefix-f
2. Visible words get yellow hint boxes
3. Type the 2-letter code (e.g., "ab") to select text
4. Text is copied to clipboard
5. Paste with cmd-v or prefix-] in tmux copy mode
```

**Examples**:
- Copy error messages from logs
- Copy URLs from terminal output
- Copy file paths
- Copy commit hashes

## Configuration Files

- **Main config**: `/Users/ejfox/.dotfiles/.tmux.conf` (128 lines)
  - Status bar (minimal, no colors)
  - Keybindings
  - Plugin declarations
  - Theme settings (matches terminal theme)

- **Local overrides**: `~/.tmux.conf.local` (auto-loaded if exists)
  - Override settings per machine
  - Session-specific configs

## Visual Design

- **Status bar**: Top position, minimal
  - Left: Prefix indicator (◼ when active)
  - Center: Window list with pane count symbols (⚌ ☰ ⚍)
  - Right: Empty (clean minimal look)
- **Panes**: Arrow indicators, subtle borders, no colors
- **Terminal colors**: Inherit from terminal emulator theme

## Performance

- 0ms escape time for nvim responsiveness
- 10,000 line history buffer
- Mouse mode enabled
- Passthrough enabled for images

## Tips

### Copy from tmux to system clipboard
```bash
# In copy mode:
Space               # Start selection
hjkl / arrows       # Navigate
Enter               # Copy (auto to clipboard via tmux-yank)

# Or use tmux-fingers:
prefix-f            # Activate
type hint code      # Auto-copy to clipboard
```

### Create and switch sessions quickly
```bash
# Create new session:
prefix-C-c

# Switch sessions:
prefix-C-f          # Find/switch (tmux-fzf)

# Or directly:
tmux new-session -s <name>
tmux switch-client -t <name>
```

### Save/restore sessions
```bash
# Auto-save on exit (via tmux-continuum)
# Auto-restore on tmux start

# Manual save:
tmux save-session <name>

# Restore specific session:
tmux start-server && tmux attach-session -t <name>
```

## Zen Mode

Toggle zen mode for distraction-free work:
```bash
prefix-Z            # Toggle

# What it does:
# - Dims background
# - Hides status bar
# - Suspends tmux scrollback
```

## Troubleshooting

**Plugins not installing?**
```bash
# Force refresh TPM
tmux source ~/.tmux.conf
# Press prefix-I to install
```

**Colors look wrong?**
- Tmux inherits from terminal theme
- Set terminal to light/dark mode first
- Then `tmux kill-server && tmux` to restart

**Copy not working?**
- Check system clipboard access: `tmux show-environment | grep DISPLAY`
- Verify `tmux-yank` installed: `prefix-I`
- Manual copy in copy mode: `Space` → select → `Enter`

## Related Documentation

- **Main config**: `.tmux.conf`
- **Plugins installed**: `PLUGINS.md` (nvim) + this file
- **Keybindings**: See tables above + `.tmux.conf`
- **Shell integration**: `.zshrc` with tmux aliases
