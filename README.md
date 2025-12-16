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
git submodule update --init --recursive  # Initialize tmux-link-grab submodule
./sync-dotfiles.sh
```git clone https://github.com/ejfox/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./sync-dotfiles.sh
```

## What's Included

### 🔧 **Shell & Terminal**
- `.zshrc` - Modern shell with LLM integration + fuzzy finder aliases
- `.startup.sh` - AI-powered MOTD with I Ching Oracle passages
- `lib/mystical-symbols.sh` - Daily I Ching hexagrams, moon phases, cosmic symbols
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
  - `tmux-resurrect` + `tmux-continuum` - Auto-save/restore sessions with smart process resurrection

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
C-a C-s     # Save session manually
C-a C-r     # Restore session manually
```

### Tmux Session Resurrection
**Auto-save**: Every 15 minutes (via tmux-continuum)
**Auto-restore**: On tmux startup (if enabled)
**Save location**: `~/.local/share/tmux/resurrect/`

**Smart process restoration** (based on actual usage patterns):
- **Editors**: `nvim`, `vim`, `vi`
- **Viewers**: `man`, `less`, `more`, `tail`
- **TUIs**: `neomutt`, `yazi`, `lazygit`, `codex`, `toot`
- **REPLs**: `node`, `psql`
- **Dev servers**: Restores exact commands like `npm run dev`, `yarn dev`, `pnpm dev`
- **Claude Code**: Restores with `--dangerously-skip-permissions` flag intact

When you restore a session, all these processes restart in their original panes with the same working directories. Dev servers auto-start, editors reopen, database connections restore.

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

### Daily I Ching Oracle
Your terminal greets you with ancient wisdom every morning via `.startup.sh`:

**Daily Hexagram System** (`lib/mystical-symbols.sh`):
- One hexagram per day, deterministic from date: `(YYYYMMDD % 64)`
- Same hexagram all day across all terminals
- Automatically changes at midnight
- 64 hexagrams with names and wisdom phrases

**Oracle Passage** (LLM-generated):
- Synthesizes all MOTD context into contemplative I Ching-style wisdom
- References your actual tasks, calendar, repos, inbox subjects
- Non-rhyming, observational style (not poetry)
- Uses `gpt-4o-mini` for nuanced language generation

Example:
```
䷄ Waiting
  Wait with patience

FOCUS
  1) Figure out documents for IRS
  2) File 2023 taxes
  ...

䷄ ORACLE
  The hexagram invites a pause amidst the flurry of tasks.
  Documents for the IRS lie before you, a testament to diligence.

  Action required on the edges of the inbox whispers caution.
  While the repositories accumulate like branches in a grove,
  The moon waxes gibbous, guiding reflection and steady choice.
```

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
| **Startup MOTD** | `.startup.sh` | AI-powered MOTD with daily I Ching Oracle |
| **Mystical Symbols** | `lib/mystical-symbols.sh` | Reusable library: I Ching hexagrams, moon phases, cosmic glyphs |
| **Powerlevel10k** | `.p10k.zsh` | Terminal prompt theme |
| **Neovim** | `.config/nvim/` | LazyVim with 45+ plugins [See PLUGINS.md](./.config/nvim/PLUGINS.md) |
| **Tmux** | `.tmux.conf` (200 lines) | Pane-based workflow with popups |
| **Vim** | `.vimrc` (19 lines) | Basic vim config |
| **Ghostty** | `.config/ghostty/` | Terminal with transparent backgrounds |
| **Sketchybar** | `.config/sketchybar/` | macOS menu bar with CIPHER coach |
| **Yazi** | `.config/yazi/` | File manager with fzf + bookmarks |
| **Tips** | `tips.txt` | Reference system for all shortcuts |
| **Git** | `.gitconfig`, `.gitignore` | Version control settings |

## 🧠 Obsidian Publishing Pipeline

Seamless bridge between knowledge base (Obsidian) and blog (website2) with CLI tools.

### `obs` - Obsidian Vault CLI

Direct access to vault from terminal:

```bash
obs print index.md            # Read note content
obs search "draft"            # Fuzzy search note titles
obs content "publish"         # Search within note contents
obs export-ready              # Bulk export notes from year folders (not /drafts)
obs export-by-tag "blog"      # Export notes with specific tag
obs tags                       # List all tags with frequency
obs daily                      # Create/open today's daily note
obs open "note-name"          # Open in Obsidian GUI
```

**Configuration**:
- Built on [obsidian-cli](https://github.com/Yakitrak/obsidian-cli) (Go, single binary)
- Configured for: `/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox`
- Portable across vaults via `--vault` flag

**Export Ready Convention**:
- Notes in year folders (`2025/`, `2024/`, etc.) are export-ready
- Notes in `/drafts/` are never export-ready
- Location-based = simple to understand and enforces workflow naturally

### `pub` - Publishing Workflow Orchestration

Full pipeline from vault to live site:

```bash
pub status                    # Dashboard: vault stats, git status, site health
pub import                    # Pull from Obsidian → website2 content
pub watch                     # Auto-import on vault changes
pub publish                   # Full workflow: import → build → git push
pub preview blog              # Quick look at blog posts
pub info filename.md          # Show file metadata
```

**Dashboard** (`pub status`):
- 📚 Vault stats (size, file count, word count, breakdown by type)
- 🔧 Git status (branch, commits, working tree, recent changes)
- 📄 Published content counts and recent updates
- 🌐 Site health check (HTTP status + response time via curl)
- 🚀 Deployment info (node_modules, build size, scripts)
- 📊 Recent activity in vault

**Architecture**:
- Bridges Obsidian ↔ website2
- Integrates with existing `scripts/blog/import.mjs` pipeline
- Watches vault for changes via `fswatch`
- Builds site with `yarn build`
- Publishes via git commits

### Obsidian Configuration as Code

Your Obsidian settings are backed up and symlinked:

```
~/.dotfiles/.obsidian-config/
├── hotkeys.json              # Custom keybindings
├── community-plugins.json    # Installed plugins
└── snippets/text.css         # Custom CSS tweaks
```

**Benefits**:
- Version control your settings
- Replicate across vaults
- Changes in Obsidian auto-sync to dotfiles
- Review keybind changes in git diff

**Installed Plugins** (9 active):
- obsidian-linter - Auto-format markdown
- oz-image-plugin - Image handling
- better-word-count - Word stats
- obsidian-hider - Hide UI elements
- obsidian-minimal-settings - Theme customization
- cm-editor-syntax-highlight - Syntax highlighting
- file-tree-alternative - Better file explorer
- published-url - Publish link management
- obsidian-minimal-settings - Theme tweaker

### Typical Workflow

```
1. Write in Obsidian (vault auto-syncs via iCloud)
2. obs print "draft" to preview how it looks
3. pub import to sync to website2
4. pub watch for auto-import while iterating
5. pub publish when ready (builds + pushes)
6. pub status to verify everything shipped
```

### Tips

- `obs search <term>` finds things in seconds (fuzzy)
- `pub status` is your dashboard - run anytime
- `pub watch` is great for iterating on posts
- Settings symlinks mean one edit applies everywhere
- All content is version-controlled in git

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

### tmux-link-grab - Elegant Seek Mode for URLs & IPs
**Keybinding**: `C-a s`

One of the most useful recent additions. Opens an interactive popup where you can instantly grab any URL or IP from your window's scrollback:

```bash
C-a s       # Enter seek mode
            # Fzf popup shows all URLs & IPs from window, numbered
1           # Type a number to select
↵           # Enter - URL copied to clipboard, status bar flashes
```

**What it captures:**
- `https://example.com/path?query=value` - URLs with full protocols
- `ftp://files.server.com` - FTP links
- `192.168.1.1` - IPv4 addresses
- `10.0.0.1:8080` - IPs with ports

**Why it's good:**
- Searches **entire window** (all panes) not just current pane
- Searches **last 100 lines** of scrollback
- Number-based selection (like vim's `s` keybinding)
- Visual feedback (status bar flashes on copy)
- Works across macOS/Linux (detects pbcopy/xclip/wl-copy)

**See**: [tmux-link-grab](https://github.com/ejfox/tmux-link-grab) repository for details
