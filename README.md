# ◆ Dotfiles

Minimalist terminal configuration focused on functional beauty, speed-of-thought workflows, and distraction-free computing.

## Core Philosophy
- **Geometric symbols** throughout interface (◆ ◇ ○ ▪ ─)
- **Theme-agnostic** design (works in light/dark mode)
- **Zen mode** for deep focus
- **Modern CLI tools** replacing legacy commands
- **Single-buffer workflows** (oil.nvim, pane-based tmux)
- **Speed-of-thought** fuzzy finding and navigation

## Installation

```bash
git clone https://github.com/ejfox/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./sync-dotfiles.sh
```

## What's Included

### 🔧 **Shell & Terminal**
- `.zshrc` - Modern shell with LLM integration + fuzzy finder aliases
- `.startup.sh` - AI-powered MOTD with contextual information
- `.zen-mode.sh` - Toggle minimal UI mode across all apps
- `.p10k.zsh` - Minimal Powerlevel10k prompt configuration
- `tips.txt` - Comprehensive reference for all custom shortcuts (videogame loading screen style)

### ⌨️ **Terminal Multiplexer (Tmux)**
- `.tmux.conf` - Pane-based workflow with popup integrations
- **Plugins**:
  - `vim-tmux-navigator` - Seamless C-h/j/k/l navigation between nvim and tmux
  - `tmux-thumbs` - Vimium-style hints for copying text (Rust, fast)
  - `tmux-menus` - Visual TUI menu (Ctrl-\) for all tmux functions
  - `tmux-fzf` - Fuzzy finder for sessions/windows/panes
  - `tmux-resurrect` + `tmux-continuum` - Auto-save/restore sessions

### 📝 **Editor (Neovim 0.11.5)**
- LazyVim-based config with 45+ plugins
- **Essential plugins**:
  - `oil.nvim` - Filesystem-as-buffer editing (delete line = delete file)
  - `nvim-dap` - Full debugging for TS/JS/Vue
  - `kulala.nvim` - HTTP client in `.http` files
  - `git-conflict.nvim` - Visual merge conflict resolution
  - Virtual lines diagnostics (Neovim 0.11 feature)
- Native LSP bindings (gd, gr, gI, gy)
- Transparent backgrounds for Ghostty integration
- See [PLUGINS.md](./.config/nvim/PLUGINS.md) for complete list

### 🎨 **Applications**
- `ghostty/` - Terminal with opacity + blur effects
- `yazi/` - File manager with fzf search and bookmarks
- `btop/` - System monitor with transparent background
- `sketchybar/` - macOS menu bar with CIPHER coach (LLM-powered task selection)

### 🔄 **Development**
- `.gitconfig` - Clean git setup with LFS support
- `.npmrc` - Node package manager configuration
- Modern CLI replacements: `lsd`, `bat`, `dust`, `duf`, `btop`, `fd`, `ripgrep`, `zoxide`

## Key Features & Workflows

### Speed-of-Thought File Access
```bash
v           # Open nvim
n           # Browse current directory with oil.nvim
vs          # Fuzzy find files with bat preview
vg          # Grep file contents and jump to matching lines
o           # Instantly access Obsidian vault (sorted by recency)
r           # Recent files across ALL ~/code projects
tip         # Show random tip from tips.txt (loading screen vibes)
```

### Oil.nvim - Filesystem as a Buffer
**The Workflow**: Press `-` from any file to open parent directory in oil.nvim
- Delete a line → delete file
- Edit a line → rename file
- Visual select + `:d` → bulk delete
- Press `-` again → go up a level
- Single-buffer workflow, no file tree sidebar

### Tmux Popup Workflows (Pane-Based)
```bash
C-a g       # Lazygit popup (floats over panes, perfect for quick commits)
C-a K       # Yazi file manager popup
C-a S       # Scratch terminal toggle (persistent)
C-\         # tmux-menus (visual TUI for all functions, no memorizing)
C-a Space   # tmux-thumbs (vimium hints for copying text)
C-a C-y     # Yank entire pane scrollback to clipboard
C-a M-y     # Yank last 200 lines to clipboard
```

### Neovim Daily Driver Plugins
**oil.nvim** - Filesystem editing
- `-` → Open parent directory
- `<CR>` → Open file/directory
- Edit line → Rename file
- Delete line → Delete file

**nvim-dap** - Debugging
- `<leader>db` → Toggle breakpoint
- `<leader>dc` → Start/continue debugging
- `<leader>du` → Toggle debug UI

**kulala.nvim** - HTTP client
- Create `.http` files with requests
- `<CR>` → Execute request under cursor
- `[r` / `]r` → Jump between requests

**git-conflict.nvim** - Merge conflicts
- `co` → Choose ours (current branch)
- `ct` → Choose theirs (incoming)
- `cb` → Choose both
- `[x` / `]x` → Jump between conflicts

### Sketchybar CIPHER Coach
Intelligent calendar + task integration:
- Shows next timed event with countdown ("in 15m", "at 3:00")
- When no events: Reads Things tasks and highlights most joyful/appealing one
- "Supportive coach, not taskmaster" tone
- Caches messages to avoid excessive API calls
- Updates only when hour changes, tasks change, or completions change

### Tips.txt - Reference System
Comprehensive shortcuts organized by category:
- Nvim aliases and oil.nvim usage
- Tmux keybindings (all popups, navigation, copy mode)
- LSP navigation (gd, gr, gI, gy)
- Merge conflict resolution
- Git/GitHub utilities
- Advanced features (marks, telescope, yanky)
- All with app context prefixes (zsh/tmux/nvim)

## Essential Keybindings

### Tmux Navigation
```
C-a          # Prefix key
C-h/j/k/l    # Navigate panes (works in nvim too!)
M-1 to M-9   # Select pane by number
M-h/M-l      # Previous/next window
C-a -        # Split vertically (current path)
C-a _        # Split horizontally (current path)
C-a H/J/K/L  # Resize pane
```

### Tmux Copy Mode
```
C-a [        # Enter copy mode
v            # Start visual selection
y            # Yank selection to clipboard
q            # Quit copy mode
/            # Search forward
?            # Search backward
```

### Nvim LSP Navigation
```
gd           # Goto definition (native LSP)
gr           # Goto references
gI           # Goto implementation
gy           # Goto type definition
<leader>ss   # Document symbols
<leader>sS   # Workspace symbols
```

### Nvim Oil.nvim
```
-            # Open parent directory / go up a level
<CR>         # Open file/directory
<C-s>        # Open in vertical split
g.           # Toggle hidden files
```

## Modern CLI Tools

| Old | New | Purpose |
|-----|-----|---------|
| `ls` | `lsd` | Better directory listings |
| `cat` | `bat` | Syntax highlighting |
| `grep` | `ripgrep` | Way faster, regex by default |
| `find` | `fd` | Blazing fast Rust find alternative |
| `du` | `dust` | Disk usage visualization |
| `df` | `duf` | Disk free visualization |
| `top` | `btop` | System monitoring |
| `cd` | `zoxide` | Jump to frequently used directories |

## Configuration Coverage

| Application | Config Location | Description |
|------------|-----------------|-------------|
| **Shell (Zsh)** | `.zshrc` (447 lines) | Main shell config with fuzzy finder aliases, PATH setup |
| **Powerlevel10k** | `.p10k.zsh` | Terminal prompt theme |
| **Neovim** | `.config/nvim/` | LazyVim with 45+ plugins [See PLUGINS.md](./.config/nvim/PLUGINS.md) |
| **Tmux** | `.tmux.conf` (200 lines) | Pane-based workflow with popups |
| **Vim** | `.vimrc` (19 lines) | Basic vim config |
| **Ghostty** | `.config/ghostty/` | Terminal with transparent backgrounds |
| **Sketchybar** | `.config/sketchybar/` | macOS menu bar with CIPHER coach |
| **Yazi** | `.config/yazi/` | File manager with fzf + bookmarks |
| **Tips** | `tips.txt` | Reference system for all shortcuts |
| **Git** | `.gitconfig`, `.gitignore` | Version control settings |

## Security Notes

**Secrets handling:**
- All API keys moved to `~/.env` (gitignored)
- Never commit `.env` files
- Scrubbed 9 API keys from git history (Nov 15, 2025)
- Improved `.gitignore` to prevent future leaks

**Action required if pulling old commits:**
- Rotate any exposed API keys
- Check GitHub security alerts

## Performance

- **Neovim startup**: < 100ms (45+ plugins, all lazy-loaded)
- **Tmux popups**: Instant (lazygit, yazi, scratch terminal)
- **Fuzzy finders**: Rust-based (fd, ripgrep) for speed
- **Oil.nvim**: Single-buffer workflow, no sidebar overhead

## Related Documentation

- **Nvim plugins**: [PLUGINS.md](./.config/nvim/PLUGINS.md) - Complete plugin inventory
- **Memory**: [CLAUDE.md](./CLAUDE.md) - Claude Code session memory
- **Tips**: `tips.txt` - All shortcuts and keybindings

---

*Every pixel serves a purpose. Maximum functionality, minimum distraction.*
