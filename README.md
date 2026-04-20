# ejfox's dotfiles

Terminal-first development environment optimized for speed-of-thought computing. Everything is fuzzy-searchable, keyboard-driven, and designed to get out of your way.

**Two ways to use this README:**
- **New Mac?** Start at [Quick Start](#quick-start) and follow the setup
- **Guest computer?** Browse the [Keybinding Reference](#keybinding-reference) to remember your muscle memory

---

## Table of Contents

- [Quick Start (New Mac)](#quick-start-new-mac)
- [Philosophy](#philosophy)
- [Keybinding Reference](#keybinding-reference)
  - [Shell](#shell)
  - [Tmux](#tmux)
  - [Neovim](#neovim)
  - [Git](#git)
- [What's Here](#whats-here)
- [Custom Scripts (bin/)](#custom-scripts-bin)
- [Neovim Setup](#neovim-setup)
- [Ghostty Terminal](#ghostty-terminal)
- [Sketchybar](#sketchybar)
- [LLM Integration](#llm-integration)
- [Cheatsheets](#cheatsheets)
- [Usage Logging](#usage-logging)
- [Secrets](#secrets)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Docs](#docs)

---

## Quick Start (New Mac)

### 1. Install Homebrew and core tools

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install neovim tmux zsh fzf ripgrep fd bat lsd zoxide atuin
brew install --cask ghostty
```

### 2. Clone and sync

```bash
git clone https://github.com/ejfox/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./sync-dotfiles.sh
```

This pulls latest, symlinks everything into place, and enables security hooks.

### 3. Set up secrets

```bash
# Create ~/.env (gitignored, sourced automatically by .zshrc)
cat > ~/.env << 'EOF'
export ANTHROPIC_API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."
# Add other keys as needed
EOF
chmod 600 ~/.env
```

### 4. Finish Neovim setup

```bash
nvim  # Opens LazyVim, plugins auto-install on first launch
# Then inside nvim:
# :Lazy sync
# :Mason          (install LSP servers)
# :checkhealth
```

### 5. Optional extras

```bash
brew install lazygit yazi icalbuddy neofetch
brew install --cask karabiner-elements
# Sketchybar (menu bar)
brew tap FelixKratz/formulae && brew install sketchybar
# macOS defaults
./scripts/macos-defaults.sh
```

### 6. Verify everything

```bash
source ~/.zshrc
dotfiles-verify   # Runs checklist of what's working
```

---

## Philosophy

**Fuzzy find everything.** Don't navigate folder trees -- search. `vs` finds files, `vg` searches content, `o` opens notes.

**Pane-based workflow.** One tmux session, multiple panes visible at once. Editor, terminal, logs, server -- all on screen together.

**Popup workflows.** `C-a g` opens lazygit floating over your panes. Do your thing, close it, layout untouched.

**Single-buffer file management.** oil.nvim opens directories as editable buffers. Delete a line = delete the file. No sidebar.

**Same keys everywhere.** `C-h/j/k/l` moves between vim splits AND tmux panes seamlessly (vim-tmux-navigator).

**AI as suggestion engine, not autopilot.** Commit messages, morning priorities, diagnostics -- AI proposes, you choose.

| Tool | Why |
|------|-----|
| **Neovim** | Terminal-native, <100ms startup with 20+ plugins |
| **Tmux** | Persistent sessions, pane layout survives restarts |
| **Zsh** | POSIX-compatible + great plugin ecosystem |
| **Ghostty** | Zig-based, GPU-accelerated, custom GLSL shaders |
| **LazyVim** | Sensible defaults, lazy-loaded, well-maintained |

---

## Keybinding Reference

Keep this section bookmarked. This is the stuff you'll forget on a guest machine.

### Shell

```
v              Open neovim
vs             Fuzzy find files (with preview)
vg             Grep file contents, jump to match
o              Fuzzy find Obsidian notes
r              Recent files across all projects
c              Clear terminal + refresh
l / ll / la    lsd directory listings
cheatsheet     Open HTML cheatsheet in Safari
```

### Tmux

```
C-a            Prefix key (not C-b)
C-h/j/k/l     Move between panes (works in vim too)
C-a g          Lazygit popup (floating, no layout disruption)
C-a K          Yazi file manager popup
C-a S          Scratch terminal popup (persistent, toggle on/off)
C-a Space      tmux-thumbs (vimium-style copy any visible text)
C-a -          Split horizontal
C-a _          Split vertical
C-a C-y        Yank entire pane scrollback to clipboard
C-a M-y        Yank last 200 lines to clipboard
```

### Neovim

**Navigation:**
```
gd             Go to definition (native LSP, not Telescope)
gr             Go to references
gI             Go to implementation
gy             Go to type definition
K              Hover documentation
<leader>ca     Code actions
<leader>rn     Rename symbol
<leader>ss     Document symbols
<leader>sS     Workspace symbols
gai            Incoming calls
gao            Outgoing calls
```

**File management (oil.nvim):**
```
-              Open parent directory as buffer
<CR>           Open file/directory
(edit line)    Rename file
(delete line)  Delete file
g.             Toggle hidden files
<C-s>          Open in vertical split
```

**Code folding (nvim-ufo):**
```
zo             Open fold
zc             Close fold
za             Toggle fold
zR             Open all folds
zM             Close all folds
zK             Peek inside fold
zj / zk        Jump between folds
```

**Git diff navigation:**
```
<leader>gm     Diff gutter vs main (gitsigns)
<leader>gp     Diff gutter vs PR base (auto-detects via gh)
<leader>gH     Reset diff to HEAD
<leader>gM     Side-by-side split diff vs main
<leader>gj     Git jump vs main (quickfix list, use ]q/[q)
]h / [h        Jump between hunks
```

**Debugging (nvim-dap):**
```
<leader>db     Toggle breakpoint
<leader>dc     Start/continue
<leader>di     Step into
<leader>do     Step over
<leader>dO     Step out
<leader>dt     Terminate
<leader>du     Toggle debug UI
<leader>de     Eval expression
```

### Git

```
C-a g          Lazygit popup (preferred way to do git)
  a            AI commit (in lazygit: generates 3 options via Claude, pick with fzf)
gs             git status
ga             git add
gc             git commit
gp             git push
```

---

## What's Here

```
~/.dotfiles/
├── .zshrc                  # Shell config (~750 lines: aliases, PATH, functions)
├── .tmux.conf              # Tmux keybindings, plugins, popups
├── .startup.sh             # Terminal MOTD (oracle, calendar, stats)
├── .p10k.zsh               # Powerlevel10k prompt theme
├── .llm-persona.txt        # CIPHER personality for AI features
├── .gitconfig               # Git config
├── .config/
│   ├── nvim/               # Neovim (LazyVim + 21 custom plugins)
│   │   ├── lua/plugins/    # Plugin configs
│   │   ├── lua/config/     # Keymaps, options
│   │   ├── colors/         # 8 vulpes colorscheme variants
│   │   ├── cheatsheet.html # Nvim keybinding reference
│   │   └── ...
│   ├── ghostty/            # Terminal emulator
│   │   ├── config          # Settings + shader stack
│   │   ├── shaders/        # 52 GLSL shaders (3 active)
│   │   └── themes/         # Vulpes color themes
│   ├── lazygit/            # Git TUI (AI commit integration)
│   ├── sketchybar/         # macOS menu bar (30 plugins)
│   ├── yazi/               # File manager (vulpes theme)
│   ├── btop/               # System monitor (vulpes theme)
│   ├── karabiner/          # Keyboard remapping
│   ├── atuin/              # Shell history sync
│   ├── bat/                # Syntax-highlighted cat
│   ├── neomutt/            # Terminal email
│   └── cheatsheet.html     # Master combined cheatsheet
├── bin/                    # 22 custom scripts
├── docs/                   # Extended documentation
├── scripts/                # Setup scripts (macOS defaults, VPS)
├── talon-overrides/        # Voice control config
└── CLAUDE.md               # AI pair programming context
```

---

## Custom Scripts (bin/)

All scripts are symlinked to `~/bin/` by PATH. Run any of them directly.

| Script | What it does |
|--------|-------------|
| `ai-commit` | Generates 3 conventional commit messages via Claude, pick with fzf |
| `morning-ritual` | CIPHER analyzes your day (Things, calendar, git, Obsidian) and suggests 12 ranked pomodoros |
| `cipher-daily` | Daily CIPHER wisdom |
| `claude-say` | Text-to-speech with adaptive playback |
| `cheatsheets` | Open HTML cheatsheets in Safari (`cheatsheets nvim` / `cheatsheets lazygit` / `cheatsheets`) |
| `obs` | Obsidian CLI utilities |
| `pub` | Publishing workflow |
| `email-summary` | Email digest generation |
| `usage-summary` | Today's shell/nvim/tmux stats |
| `usage-analyze` | Pattern analysis over N days |
| `usage-log` | Log activity events (called by hooks) |
| `appearance-watcher` | React to macOS light/dark mode changes |
| `dotfiles-verify` | Check that everything is symlinked and working |
| `dotfiles-audit` | Audit dotfiles integrity |
| `send-to-canvas` | Send content to Canvas |
| `vps` | VPS connection utility |
| `tmux-scratch-toggle` | Toggle persistent scratch terminal |
| `tmux-focus-color` | Pane focus indicator |
| `tmux-mutagen-status` | Mutagen sync status |
| `mic-toggle` | Microphone on/off |
| `btop` | System monitor wrapper |
| `vtsls-wrapper` | TypeScript LSP wrapper for Vue hybrid mode |

---

## Neovim Setup

Based on [LazyVim](https://www.lazyvim.org/) with 21 custom plugin configs. Starts in <100ms.

### Plugin Overview

| Plugin | Purpose |
|--------|---------|
| **oil.nvim** | Filesystem as editable buffer (replaces file tree) |
| **vim-tmux-navigator** | `C-h/j/k/l` across vim splits and tmux panes |
| **nvim-ufo** | Treesitter-powered code folding |
| **nvim-dap** | Full debugging for TypeScript/JavaScript/Vue |
| **gitsigns** | Git diff gutter + diff vs main/PR base |
| **git-conflict.nvim** | Visual merge conflict resolution (`co`/`ct`/`cb`) |
| **vue-lsp** | Volar 2.0 hybrid mode + vtsls for Vue/Nuxt |
| **kulala.nvim** | HTTP client (`.http` files, like Postman in nvim) |
| **mini.animate** | Subtle cursor/resize animations (scroll disabled) |
| **obsidian.nvim** | Obsidian vault integration |
| **usage-logging** | Track editing patterns to JSON |
| **copilot-inline** | GitHub Copilot suggestions |
| **snacks.nvim** | UI enhancements (notifications, picker) |
| **tailwind** | Tailwind CSS completions and colors |
| **svelte** | Svelte language support |

### Vue/Nuxt LSP (Volar 2.0 Hybrid Mode)

Volar 2.0 split into two servers. Both must be running in `.vue` files:
- **vue_ls** (Volar): handles `<template>` and `<style>`
- **vtsls** + `@vue/typescript-plugin`: handles `<script lang="ts">`

Config: `.config/nvim/lua/plugins/vue-lsp.lua`

If `gd` returns 0 results in Vue files, check `:lua print(vim.inspect(vim.lsp.get_clients({bufnr=0})))` -- you should see both `vtsls` AND `vue_ls`.

### Colorscheme

8 vulpes variants in `.config/nvim/colors/`. Dark theme with red/pink accents. Backgrounds set to transparent to use Ghostty's transparency.

### Key Config Decisions

- **Native LSP** for `gd`/`gr`/etc, not wrapped in Telescope/Snacks (fewer layers = more reliable)
- **oil.nvim** over file tree sidebar (filesystem = buffer)
- **Lazy loading** everything (plugins load on first use)

---

## Ghostty Terminal

Config: `.config/ghostty/config`

### Shader Stack (3 active out of 52 available)

Applied in order:
1. **cursor-blaze-vulpes.glsl** -- Hot pink cursor trail, velocity-reactive
2. **bloom-vulpes.glsl** -- Red-selective glow (only blooms warm colors)
3. **tft-subtle.glsl** -- Subtle LCD subpixel effect

Reload shaders: `Cmd+Shift+,`

The other 49 shaders (matrix, CRT, starfield, film grain, etc.) are available in `.config/ghostty/shaders/` if you want to swap them in.

### Vulpes Theme

Dark background, red/pink accents. Consistent across ghostty, nvim, lazygit, yazi, btop, sketchybar, and tmux.

---

## Sketchybar

macOS menu bar replacement with 30 plugin scripts. Config: `.config/sketchybar/`

Highlights:
- **next_event**: Calendar countdown + CIPHER coach (suggests joyful tasks when no events soon)
- **battery**: OLED black background, fades to red below 50%
- **creative**: Consolidated demos/notes/words tracker with staleness warnings

---

## LLM Integration

AI is used as suggestion engine, not autopilot. You always pick the final action.

| Feature | How it works |
|---------|-------------|
| **ai-commit** | Stages changes -> Claude generates 3 conventional commit messages -> fzf picker with diff preview -> you choose |
| **morning-ritual** | Gathers Things tasks, calendar, git activity, Obsidian notes, command history -> CIPHER ranks 12 pomodoros -> you multi-select top 3 -> added to Things |
| **startup oracle** | Daily contextual wisdom shown on terminal open |
| **CIPHER coach** | Sketchybar widget suggests tasks when calendar is clear |

All use the CIPHER personality (`.llm-persona.txt`): terse, William Gibson meets Unix philosophy, dry wit.

API keys live in `~/.env`. Outputs are cached to avoid redundant calls.

---

## Cheatsheets

Beautiful dark-themed HTML reference pages with all your keybindings.

```bash
cheatsheet           # Open master (nvim + lazygit combined) in Safari
cheatsheets nvim     # Nvim only
cheatsheets lazygit  # Lazygit only
```

Files:
- `.config/cheatsheet.html` -- master combined
- `.config/nvim/cheatsheet.html` -- nvim bindings
- `.config/lazygit/cheatsheet.html` -- lazygit bindings

Park one on your second monitor.

---

## Usage Logging

Tracks shell commands, nvim editing, and tmux pane activity to JSON lines files for pattern analysis.

```bash
usage-summary              # Today's stats
usage-summary 2025-01-20   # Specific day
usage-analyze              # Last 7 days pattern analysis
usage-analyze 30           # Last 30 days
```

Logs: `~/.local/share/usage-logs/{shell,nvim,tmux}/YYYY-MM-DD.jsonl`

Good for finding: alias candidates, hot files, slow commands, workspace patterns.

---

## Secrets

**Never commit secrets.** API keys go in `~/.env` (gitignored):

```bash
# ~/.env -- chmod 600
export ANTHROPIC_API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."
```

`.zshrc` sources this file automatically. A pre-commit hook (`.githooks/`) scans for leaked secrets.

---

## Customization

**Add aliases:** Edit `~/.dotfiles/.zshrc`, then `source ~/.zshrc`

**Add nvim plugins:** Create `.config/nvim/lua/plugins/your-plugin.lua`:
```lua
return {
  {
    "author/plugin-name",
    event = "VeryLazy",
    opts = {},
  },
}
```

**Change tmux bindings:** Edit `~/.dotfiles/.tmux.conf`, then `tmux source ~/.tmux.conf`

**Swap ghostty shaders:** Edit `.config/ghostty/config`, change the `custom-shader` lines, then `Cmd+Shift+,`

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Neovim plugins not loading | `:Lazy sync` |
| Tmux changes not applying | `tmux source ~/.tmux.conf` |
| LSP not working | `:LspInfo` and `:Mason` for missing servers |
| "Command not found" | Ensure `/opt/homebrew/bin` is in PATH |
| Vue `gd` returns 0 results | Check both `vtsls` and `vue_ls` are attached (`:LspInfo`) |
| Shaders not loading | `Cmd+Shift+,` to reload Ghostty config |
| Symlinks broken | `cd ~/.dotfiles && ./sync-dotfiles.sh` |
| Everything broken | `dotfiles-verify` to run the full checklist |

---

## Docs

| File | What's in it |
|------|-------------|
| `CLAUDE.md` | AI pair programming context (git rules, secrets, integrations) |
| `docs/tips.txt` | Complete keybinding cheatsheet (shown randomly on startup) |
| `docs/WORKFLOWS.md` | Advanced CLI pipelines (obs, pub, llm) |
| `docs/STARTUP_DOCS.md` | How the startup script and morning ritual work |
| `docs/TWEAKCC_SETUP.md` | TweakCC configuration |
| `docs/HISTORY.md` | Changelog |

---

*Minimal config, maximum velocity.*
