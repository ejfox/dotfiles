# ejfox's dotfiles

Terminal-first development environment optimized for speed-of-thought computing. Everything is fuzzy-searchable, keyboard-driven, voice-controllable, and wired into ambient lighting, a Windows GPU box, and a wall of custom telemetry. It is designed to get out of your way — and occasionally to glow pink at you.

This is a big config. About 550 tracked files, ~130 scripts, a Rust cheatsheet TUI, 22 Neovim plugin configs, a voice-control layer, an ambient-lighting protocol, a persistent-model art wall, and a small video-studio rig (OBS config, a recording terminal, booth scripts). The README is long on purpose; use the table of contents.

**Three ways to read this:**
- **New Mac?** Start at [Quick Start](#quick-start-new-mac) and follow the setup.
- **Guest computer?** Jump to the [Keybinding Reference](#keybinding-reference) to reload your muscle memory.
- **Spelunking?** The [Repository Layout](#repository-layout) map links to every subsystem's deep-dive section below.

Host machine: **Intel iMac** running macOS. A few choices exist specifically because this is x86_64 hardware: Ghostty shaders off by default, a pinned node path, Neovim from a release tarball, and CLI tools from release binaries (`bin/relbins`) instead of Homebrew source builds.

---

## Table of Contents

- [Quick Start (New Mac)](#quick-start-new-mac)
- [Philosophy](#philosophy)
- [Keybinding Reference](#keybinding-reference)
  - [Shell](#shell)
  - [Tmux](#tmux)
  - [Neovim](#neovim)
  - [Git](#git)
  - [Talon (voice)](#talon-voice)
- [Repository Layout](#repository-layout)
- [Shell & Zsh](#shell--zsh)
- [Neovim](#neovim-setup)
- [Ghostty Terminal](#ghostty-terminal)
- [Theme System (light/dark)](#theme-system-lightdark)
- [Cheatsheet System](#cheatsheet-system)
- [Sketchybar (menu bar)](#sketchybar-menu-bar)
- [Custom Scripts (bin/)](#custom-scripts-bin)
- [computah — Windows GPU Box](#computah--windows-gpu-box)
- [Ambient Lighting & Hardware](#ambient-lighting--hardware)
- [Talon Voice Control](#talon-voice-control)
- [Hammerspoon](#hammerspoon)
- [Scheduled Jobs (LaunchAgents)](#scheduled-jobs-launchagents)
- [LLM / CIPHER Integration](#llm--cipher-integration)
- [Usage Logging](#usage-logging)
- [Helper Libraries (lib/)](#helper-libraries-lib)
- [Claude Code Config](#claude-code-config)
- [Other Configs](#other-configs)
- [Secrets & Security](#secrets--security)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Docs](#docs)

---

## Quick Start (New Mac)

### 1. Install Homebrew and core tools

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install tmux zsh ripgrep fd bat lsd zoxide jq tree-sitter-cli
brew install --cask ghostty
```

`tree-sitter-cli` is required: nvim-treesitter compiles its parsers with it.

**Apple Silicon:** `brew install neovim fzf atuin lazygit yazi` and you're done.

**Intel:** Homebrew ships almost no Intel bottles anymore, so it compiles from source (LLVM, Qt, ffmpeg). Never run a blanket `brew upgrade` here. Instead:

```bash
bin/relbins status && bin/relbins install   # gh, fzf, lazygit, yazi, atuin, rg, fd, uv, deno… (21 CLIs)
```

`relbins` installs official release binaries into `~/.local/opt/<tool>-<ver>/` (sha256-checked, old versions kept for rollback) and symlinks them into `~/.local/bin`. Neovim 0.12 has no Intel bottle either: unpack the official release tarball into `~/.local/opt/nvim-0.12.x/`, run `xattr -dr com.apple.quarantine` on it, and point `~/.local/bin/nvim` at it.

### 2. Clone and sync

```bash
git clone https://github.com/ejfox/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./sync-dotfiles.sh
```

`sync-dotfiles.sh` pulls latest from `main` (stashing local changes if needed), symlinks every dotfile and `.config/` directory into place, wires the Talon overrides into `~/.talon/user/`, points lazygit at its `~/Library/Application Support` location, links the OBS config and the Claude agents directory, links each tracked LaunchAgent (it skips rather than clobbers a differing real file), links the Obsidian hotkeys, and enables the pre-commit security hook (`git config core.hooksPath .githooks`).

### 3. Set up secrets

Secrets live in 1Password, not in files you write by hand. Install the 1Password CLI (`op`), sign in, then:

```bash
bin/env-sync            # renders env.op → ~/.env and claude-wiki.op → ~/.claude-secrets
bin/env-sync --check    # compares variable names only, prints no values
```

`env.op` and `claude-wiki.op` hold only `op://` references, so they are safe in this public repo. The rendered files are gitignored, `chmod 600`, and sourced by `.zshrc`. Change a value in 1Password and rerun `env-sync`; never edit it in the repo.

### 4. Finish Neovim setup

```bash
nvim  # LazyVim bootstraps; plugins auto-install on first launch
# then inside nvim:
# :Lazy sync
# :Mason          (install LSP servers: vtsls, vue-language-server, svelte, etc.)
# :checkhealth
```

### 5. Optional extras

```bash
brew install icalbuddy neofetch switchaudio-osx
brew install --cask karabiner-elements
brew tap FelixKratz/formulae && brew install sketchybar   # menu bar
./scripts/macos-defaults.sh                                 # opinionated macOS defaults
cd cheatsheet && cargo build --release                      # the `cheat` TUI
```

### 6. Verify everything

```bash
source ~/.zshrc
dotfiles-verify   # checklist of what's symlinked and working
dfsync            # warns on unpushed/unpulled/dirty state
```

---

## Philosophy

**Fuzzy find everything.** Don't navigate folder trees — search. `vs` finds files, `vg` searches content, `o` opens notes.

**Pane-based workflow.** One tmux session, multiple panes visible at once. Editor, terminal, logs, server — all on screen together. (No sessionizer; panes, not windows.)

**Popup workflows.** `C-a g` opens lazygit floating over your panes. Do your thing, close it, layout untouched. Same for `C-a S` (scratch) and `C-a f` (fuzzy jump to any pane).

**Single-buffer file management.** oil.nvim opens directories as editable buffers. Delete a line = delete the file. No sidebar.

**Same keys everywhere.** `C-h/j/k/l` moves between vim splits AND tmux panes seamlessly (vim-tmux-navigator).

**AI as suggestion engine, not autopilot.** Commit messages, morning priorities, diagnostics — AI proposes, you choose. The persona is CIPHER (`.llm-persona.txt`).

**The computer is multi-sensory.** Lights flash on events, a desk display shows telemetry, and voice drives the terminal. Signal, not noise: the flash grammar is a traffic light (white FYI, green done, yellow needs you, red error).

**Tracked sources, gitignored live state.** Theme flips swap symlinks/copies that are gitignored, so switching light↔dark almost never dirties the repo (delta is the one exception, see [Theme System](#theme-system-lightdark)).

| Tool | Why |
|------|-----|
| **Neovim** | Terminal-native, LazyVim on nvim 0.12, 22 custom plugin configs |
| **Tmux** | Persistent sessions, pane layout survives restarts |
| **Zsh** | Fast startup (node path pinned), great plugin ecosystem |
| **Ghostty** | Zig-based, GPU-accelerated, optional GLSL shader stack |
| **Talon** | Hands-free voice control layered over the whole stack |
| **Rust (ratatui)** | The `cheat` TUI — one TOML source, two renderers |

---

## Keybinding Reference

Keep this section bookmarked. This is the stuff you'll forget on a guest machine. The canonical, always-current copy lives in [`cheatsheet/cheatsheet.toml`](#cheatsheet-system) (`cheat` in any pane).

### Shell

```
v / n          Open neovim / neovim in this directory
vs             Fuzzy find files (with preview)
vg             Grep file contents, jump to match
o              Fuzzy find Obsidian notes
r              Recent files across all projects
y              Yazi file manager
c              Clear terminal
l / ll / la    lsd directory listings
z              zoxide jump
tips / tip     Fuzzy-search the tips file / one random tip
note "text"    Append a line to the vault inbox
cheat          Cheatsheet TUI (ratatui)
cheatsheet     Cheatsheet panel (alias for `cheatsheets`)
theme          Re-sync all tools to current light/dark mode
```

### Tmux

```
C-a            Prefix key (not C-b)
C-h/j/k/l      Move between panes (works in vim too)
C-a H/J/K/L    Resize pane by 5
C-a g          Lazygit popup (floating, no layout disruption)
C-a S          Scratch terminal popup (persistent, toggle on/off)
C-a f          Fuzzy jump to any pane
C-a Z          Reading mode: center the active pane in a fixed-width column
C-a Space      Scrollback in nvim (searchable, colorized; :q returns)
C-a -          Split below
C-a _          Split right
C-a D          Dev-server strip below
C-a G          gh browse
C-a ?          Tips popup
C-a N          Quick note to the vault inbox
C-a C-y        Yank entire pane scrollback to clipboard
C-a M-y        Yank last 200 lines to clipboard
```

### Neovim

**Navigation (LSP keys come from LazyVim, set per buffer on LspAttach):**
```
gd             Go to definition
gr             Go to references
gI             Go to implementation
gy             Go to type definition
K              Hover documentation
<leader>ca     Code actions
<leader>rn     Rename symbol
<leader>ss     Document symbols
<leader>sS     Workspace symbols
gai / gao      Incoming / outgoing calls
<leader>fv     Open project .env
```

**File management (oil.nvim):**
```
-              Open parent directory as buffer
<CR>           Open file/directory
(edit line)    Rename file
(delete line)  Delete file
g.             Toggle hidden files
<leader>- / <leader>|   Open in split
```

**Folding (nvim-ufo):**
```
zo / zc / za   Open / close / toggle fold
zR / zM        Open all / close all
zK             Peek inside fold
zj / zk        Jump between folds
```

**Git (gitsigns + git-conflict):**
```
<leader>gm     Diff gutter vs main
<leader>gM     Split diff vs main
<leader>gp     Diff gutter vs PR base (auto-detects via gh)
<leader>gH     Reset diff base to HEAD
<leader>gj     Git jump vs main (quickfix; use ]q/[q)
]h / [h        Jump between hunks
co / ct / cb   Conflict: choose ours / theirs / both
```

**Debugging (nvim-dap):**
```
<leader>db     Toggle breakpoint
<leader>dc     Start/continue
<leader>di/do/dO   Step into / over / out
<leader>dt     Terminate
<leader>du     Toggle debug UI
<leader>de     Eval expression
```

**AI ghost text (native inline completion):**
```
<Tab>          Accept suggestion / jump to and apply the next edit
<C-Right>      Accept one word
<C-l>          Accept one line
<M-]> / <M-[>  Cycle suggestions
<leader>uN     Toggle next-edit suggestions
```

**Focus & misc:**
```
<leader>Z      Zen mode
<leader>up     Prose mode (narrow, no numbers)
<leader>uw     Toggle wrap
<leader>ut     Toggle dim (snacks.dim: dims inactive code)
<leader>sl/st/su/sq   Strudel: launch / toggle play / eval / quit
<leader>yr/ya  (visual) Copy selection with relative / absolute path + line range
```

### Git

```
C-a g          Lazygit popup (preferred way to do git)
  a            AI commit — 3 Claude-generated options, pick with fzf
  <c-a>        AI commit, inline menu
  <c-b>        AI commit, edit the message first
gst / ga / gc / gp   status / add / commit / push
git cs         Signed commit (commit -S)
```

### Talon (voice)

```
mux next/previous/last/left/right/up/down/zoom/close     Tmux control
mux split right / mux split down                         Splits
run claude/codex/neovim/lazygit/yazi/btop                Launch tools
go home/code/dotfiles/website/vulpes/…                   cd shortcuts
git status/log/diff/push/pull/stash                      Git verbs
wipe line/word/ahead, cancel, clear screen               Line editing
remote next/previous/last/<n> (Ctrl-B prefix)            Nested/remote tmux
```

---

## Repository Layout

```
~/.dotfiles/
├── .zshrc                  # Shell config (~465 lines: aliases, PATH, functions)
├── .zshenv / .zprofile     # zsh env (all invocations) / login-once profile
├── .bash_profile           # minimal, defers to zsh
├── hosts/                  # Per-machine zsh overrides, auto-loaded by hostname
├── .tmux.conf              # Tmux keybindings, plugins, popups
├── .startup.sh             # Terminal MOTD (oracle, calendar, stats)
├── .zen-mode.sh            # Simple zen-mode toggle
├── .p10k.zsh               # Powerlevel10k prompt theme
├── .llm-persona.txt        # CIPHER personality for AI features
├── .gitconfig / .gitattributes / .gitignore
├── .githooks/pre-commit    # Secret scanner (blocks commits with leaks)
├── env.op / claude-wiki.op # 1Password references (op://) rendered by env-sync; no values
├── .config/                # ~180 tracked files across 14 app configs
│   ├── nvim/               # Neovim (LazyVim + 22 plugin configs, 8 colorschemes)
│   ├── nvim-pack/          # `nvp` experiment: vim.pack + mini.nvim, no LazyVim
│   ├── ghostty/            # Terminal (config + 52 shaders + themes)
│   ├── sketchybar/         # macOS menu bar (11 plugin scripts)
│   ├── lazygit/            # Git TUI (AI-commit keys, light/dark themes)
│   ├── yazi/ btop/ bat/ fzf/   # File mgr / sysmon / cat / fuzzy — all themed light+dark
│   ├── atuin/              # Shell history
│   ├── karabiner/          # ⌥Space leader + WINDOW-MODE.md
│   ├── claude/ zsh/        # tmux MCP server + zsh prompt palettes
│   ├── minimal-prompt.zsh  # Minimal prompt matching tmux/nvim aesthetic
│   └── cheatsheet.html     # Generated cheatsheet panel (from cheatsheet.toml)
├── bin/                    # ~130 custom scripts (see tables below)
├── lib/                    # Shared libraries (usage logging, pixel kit, music-cli)
├── cheatsheet/             # Rust/ratatui cheatsheet TUI — SINGLE source of truth
├── hue-stream/             # Hue Entertainment daemon + PC RGB sync
├── hammerspoon/            # Window snapping, autoplace, hue-key, OBS helpers
├── talon-overrides/        # 20-file voice control layer
├── LaunchAgents/           # 8 scheduled jobs (+ one laptop-only in ejfmbp/)
├── obs/                    # OBS Studio config (scenes, profile, MIDI bindings, LUTs)
├── ghostty-studio/         # Separate Ghostty instance for recording terminal demos
├── computah/               # Files that live on the Windows PC (wall/ops pages, kit.css)
├── scripts/                # Setup + weekly-review scripts
├── docs/                   # Extended documentation (see Docs table)
├── .obsidian-config/       # Tracked Obsidian hotkeys/plugins/snippets (not vault content)
├── .irssi/themes/          # IRC theme (config itself is gitignored — holds passwords)
├── .claude/                # Claude Code settings snapshot, skills, 17 agent personas
├── rclone-backup-filters.txt   # Exclude list for `laptop-backup`
├── vulpes-reddish2-{dark,light}-tmux.tmux.conf   # tmux theme variants
├── sync-dotfiles.sh        # Symlink installer
├── LICENSE                 # Unlicense (public domain)
└── CLAUDE.md               # Rules and gotchas for AI pair-programming
```

---

## Shell & Zsh

The shell is the front door. Startup is kept fast by pinning the node path instead of invoking `nvm use` (with a fallback to the newest installed node), and by caching atuin's init.

| File | Role |
|------|------|
| `.zshenv` | Runs for **all** zsh invocations (interactive, login, scripts, ssh commands). Minimal, PATH-critical. |
| `.zprofile` | Runs **once per login** session. |
| `.zshrc` | The active config (~465 lines): aliases (`vs`/`vg`/`o`/`r`), functions (`tips`, `note`, `yank`, `ask`, `vps`), PATH, plugin loads, sources `~/.env`, loads usage-logging hooks. Detects Intel vs Apple Silicon Homebrew. Symlinked from `~/.zshrc`. |
| `hosts/<hostname>.zsh` | Per-machine overrides (`imacpro.zsh`, `ejfmbp.zsh`), sourced automatically by short hostname. |
| `.bash_profile` | Minimal — defers to zsh for the real config. |
| `.p10k.zsh` | Powerlevel10k prompt theme. |
| `.config/minimal-prompt.zsh` | Alternative minimal prompt matching the tmux/nvim aesthetic. |
| `.startup.sh` | Terminal MOTD shown on open — oracle poem, calendar, stats, a random tip. Precached by a LaunchAgent so first-open is instant. |
| `.zen-mode.sh` | Simple zen-mode toggle for distraction-free work. |
| `lib/shell-usage-logging.zsh` | `preexec`/`precmd` hooks that log commands, `cd`s, and sessions to JSONL (see [Usage Logging](#usage-logging)). |

Gotcha: `c` is an alias, so a shell function named `c()` won't parse.

Shell sync between machines is origin-only: commit + push from each box. `dfsync` warns at shell start on unpushed/unpulled/dirty state. There is exactly **one** clone (`~/.dotfiles`).

---

## Neovim Setup

Based on [LazyVim](https://www.lazyvim.org/) on Neovim **0.12** (the official release build in `~/.local/opt`, since Homebrew has no Intel bottle), with **22 custom plugin configs** in `.config/nvim/lua/plugins/`. `init.lua` is a single `require("config.lazy")`. Most language and AI support comes from LazyVim extras (see `lazyvim.json`), not local plugin files. Background auto-switches light/dark with macOS appearance (`auto-dark-mode.nvim`, 1s check). Clipboard uses macOS `pbcopy`/`pbpaste` (OSC52 off).

### Plugins

| File | Plugin(s) | Purpose |
|------|-----------|---------|
| `oil.lua` | stevearc/oil.nvim | Filesystem as an editable buffer (replaces the file tree); git status inline |
| `utilities.lua` | vim-tmux-navigator, nvim-surround, conform | `C-hjkl` across vim/tmux; surrounds; prettier formatting |
| `nvim-ufo.lua` | nvim-ufo + promise-async | Treesitter folding with indent fallback; peek folds |
| `nvim-dap.lua` | nvim-dap + dap-ui + nio + virtual-text | Full TS/JS/Vue debugging with inline values |
| `git.lua` | gitsigns + git-conflict + oil-git-status | Diff gutter, diff vs main/PR base, conflict resolution |
| `ai.lua` | LazyVim `ai.copilot-native` + `ai.sidekick` | Native 0.12 inline-completion ghost text and next-edit suggestions (no chat) |
| `lsp-languages.lua` | bashls, cssls, html, marksman, glsl_analyzer, rust_analyzer, sourcekit | LSP for languages LazyVim has no extra for |
| `vue-lsp.lua` | nuxt-goto.nvim | Fixes `gd` redirecting to auto-import `.d.ts` files (see below) |
| `svelte.lua` | svelte-language-server + treesitter + conform | Svelte SFC support, organize imports |
| `strudel.lua` | gruvw/strudel.nvim | Live-code music: buffer ↔ strudel.cc |
| `obsidian.lua` | obsidian-nvim/obsidian.nvim | iCloud vault integration, weekly notes |
| `minimal-statusline.lua` | lualine.nvim | Custom statusline: context path, modified ◆, diagnostics, LSP icons |
| `snacks.lua` | folke/snacks.nvim | Dashboard (fox header), statuscolumn, explorer, pickers, git UI |
| `statuscolumn-tens.lua` | snacks tweak | Every 10th line shows absolute number in grey |
| `nvim-cmp-lean.lua` | blink.cmp | Completion UI (no border, vulpes colors); ghost text and `<Tab>` live in `ai.lua` |
| `notifications.lua` | snacks.notifier | Compact, fading notifications (nvim-notify + noice disabled) |
| `focus.lua` | snacks.zen + prose mode | `<leader>Z` zen (also zooms the tmux pane), `<leader>up` prose |
| `theming.lua` | auto-dark-mode + snacks.dim | Colorscheme auto-switch; `<leader>ut` dim toggle |
| `usage-logging.lua` | custom | Logs editing patterns to JSONL |
| `baleia.lua` | baleia.nvim | Renders ANSI color codes in buffers |
| `mini.lua` | (placeholder) | mini.diff/animations come via LazyVim extras + snacks |
| `miranda.lua` | ejfox/miranda.nvim | **Disabled** — daily editing coach; needs `~/.config/miranda/` provisioned |

**Config** (`lua/config/`): `keymaps.lua` (display-line `j/k`, `<leader>fv` project .env, yank-with-path, git-jump), `options.lua` (Monaspace Krypton 13pt, hybrid numbers, pbcopy clipboard, auto-reload when files change on disk), `autocmds.lua` (markdown wrap, plugin health check), `lazy.lua` (LazyVim + typescript + vue extras; disables gzip/tar/tohtml/tutor/zip builtins).

**`nvp`** launches a second, sandboxed config (`NVIM_APPNAME=nvim-pack`): nvim 0.12 natives only (`vim.pack` + mini.nvim), no LazyVim. It's an experiment; the main config is untouched.

### Vue/Nuxt LSP (Volar 2.0 hybrid mode)

Volar 2.0 split into two servers; both must run in `.vue` files:
- **vue_ls** (Volar) — `<template>` and `<style>`
- **vtsls** + `@vue/typescript-plugin` — `<script lang="ts">`

The LazyVim `lang.vue` extra wires both through native `vim.lsp.config`, and `nuxt-goto.nvim` fixes `gd` redirecting to `.d.ts` files. If `gd` returns 0 results, check `:lua print(vim.inspect(vim.lsp.get_clients({bufnr=0})))` — you should see both `vtsls` **and** `vue_ls`.

### Colorschemes

8 vulpes variants in `.config/nvim/colors/`, two naming generations:
- Older: `vulpes_reddish_{dark,light}`, `vulpes_reddish2_{dark,light}`, `vulpes_greenish_{dark,light}` (superseded/alt)
- **Active:** `vulpes-reddishnovember-{dark,light}` — warm reds, transparent bg, auto-switched

---

## Ghostty Terminal

Config: `.config/ghostty/config`. Reload with **`Cmd+Shift+R`**.

| Setting | Value |
|---------|-------|
| Font | MonaspiceKr Nerd Font (italic: MonaspiceRn) |
| Opacity | `1.0` (opaque; blur and cell-wise opacity are off to save GPU) |
| Padding | 0 (flush with sketchybar) |
| Cell size | Trimmed (`adjust-cell-height -16%`, `adjust-cell-width -10%`) for tmux density |
| Cursor | Block, non-blinking, invert fg/bg |
| Theme | Native OS switch: `light:vulpes-reddishnovember-light,dark:...-dark` |

### Shaders — off by default, opt-in per machine

The `shaders/` directory holds **52** GLSL shaders, but they are **all commented out** in the tracked `config`. Because this is an Intel iMac, the shader stack is left off for fan/thermal relief. Fast machines opt in per-host via `config.local` (gitignored, sourced by `config-file = ?config.local`).

The intended "on" stack (uncomment / drop into `config.local`):
1. `bloom-vulpes.glsl` — red-selective glow (only blooms warm pixels)
2. `tft-subtle.glsl` — subtle LCD subpixel effect
3. `vignette-vulpes.glsl` — red-accented vignette

`cursor-blaze-vulpes.glsl` (a hot-pink cursor trail) and the other ~48 (matrix, CRT, starfield, film-grain, glitch, water…) are there to swap in for fun. Helpers: `audit-ghostty-theme.mjs`, `find-vulpes-greens*.mjs`.

> If bloom is ever enabled, keep UI selections dark-bg + white-text + bold — bright saturated selections bloom into an unreadable smear. The nvim/tmux themes already account for this.

---

## Theme System (light/dark)

One command re-skins the entire stack. `bin/appearance-watcher` polls macOS appearance every **2s** and re-syncs on change; `theme` forces a manual re-sync; `theme-dark` / `theme-light` force the OS mode *and* sync.

Each tool switches by a mechanism that fits it, and the **live** file is gitignored so flipping doesn't dirty the repo (delta is the exception):

| Tool | Mechanism | Tracked source → live (gitignored) |
|------|-----------|-------------------------------------|
| Ghostty | native | `themes/vulpes-reddishnovember-{dark,light}` (OS-driven) |
| Neovim | plugin | `colors/*-{dark,light}.lua` via `auto-dark-mode.nvim` |
| Tmux | symlink repoint + `source-file` | `vulpes-reddish2-{dark,light}-tmux.tmux.conf` → `*-current-*` |
| Yazi | symlink repoint | `.config/yazi/vulpes-reddishnovember-{dark,light}.toml` → `theme.toml` |
| Fzf | symlink repoint | `.config/fzf/theme-{dark,light}.sh` → `current.sh` |
| Btop | file copy + `SIGUSR2` | `.config/btop/btop-{dark,light}.conf` → `btop.conf` |
| Lazygit | file copy | `.config/lazygit/vulpes-reddishnovember-{dark,light}.yml` → `config.yml` |
| Bat | built-in | `--theme=auto:system` (Catppuccin + vulpes tmThemes) |
| Delta | in-place `sed` | `features = {dark,light}-vulpes` in `.gitconfig` (the one tracked file the watcher rewrites) |
| Claude Code | its own setting | follows the terminal; the watcher does not touch it |

Full architecture, recovery steps, and known cruft: [`docs/THEME-SYSTEM.md`](docs/THEME-SYSTEM.md). If things look broken in either mode, just run `theme`.

---

## Cheatsheet System

The cheatsheet is a **Rust/ratatui** project in `cheatsheet/`, and `cheatsheet.toml` is the **single source of truth** for every keybinding — nvim, lazygit, tmux, Talon, computah, hue, window-mode. Edit the TOML, and both renderers update.

```bash
cheat            # ratatui TUI (j/k scroll, / search, q quit) — for tmux panes
cheat gen        # regenerate the HTML panel from the TOML
cheat dump 80    # plain-text render at width 80 (pipes/tests)
cheatsheets      # Hammerspoon floating panel (alias: cheatsheet); also `web`, `app`, `nvim`, `lazygit`, `gen`
```

Two renderers, one source:
```
cheatsheet.toml ─┬─→ cheat gen ─→ .config/cheatsheet.html   (Hammerspoon panel, ⌥Space ?)
                 └─→ cheat       ─→ ratatui TUI              (any terminal pane)
```

**TOML schema:** each card has a `tone`, an `open` flag (expanded on load), and optionally `apps` (pins the card to the top while that Mac app is frontmost). Body items are keybinding rows, dividers, sub-group labels, narrative lines (`n`), footnotes (`o`), and `strat` callouts. Inline markup: `` `x` `` = key, `*x*` = teal emphasis, `**x**` = bold. The full schema is in [`cheatsheet/README.md`](cheatsheet/README.md). The panel's tip bar and full index come from `docs/tips.txt`.

**Vulpes tokens** (`templates/shell.html`): `--base #ff4d8d` (readable pink — `#e60067` was too dark on black), `--teal #7bf0f9`, `--gold #ffd489`, `--bg #000000`, `--fg #f2cfdf`. Build: `cargo build --release` → symlink to `~/.local/bin/cheat`.

Wiki mirror: <https://archive.ejfox.com/wiki/Cheatsheet>.

---

## Sketchybar (menu bar)

macOS menu bar replacement. Config: `.config/sketchybar/sketchybarrc`, with **11** plugin scripts in `plugins/` (`_lib.sh` is a shared helper). Most items hide themselves under a macOS Focus.

Layout (left → right):
```
[talon] [mic] [next_event] ......... [foundations] [demos] [dispatch] [posts] [computah] [battery] [clock]
```

| Plugin | What it shows |
|--------|---------------|
| `next_event` | Calendar countdown w/ per-meeting colors (events with attendees only, up to 5) |
| `battery` | OLED-black bg; hides itself on desktop Macs (no battery) |
| `foundations` | Count + staleness of open 🌞 Foundation dailies; visible only outside work hours |
| `demos` | 4-week dot matrix of recordings in `~/demos` |
| `posts` | 4-week dot matrix from ejfox.com RSS pubDates (15-min cache) |
| `dispatch` | Count of recently edited vault posts not yet on ejfox.com (checked against the site RSS); click opens Dispatch |
| `computah` | The Windows PC at a glance: asleep (click wakes), idle, or busy with GPU %. Reads a cache written by `computah-probe`, never blocks on SSH |
| `talon` | Voice-control mode indicator (sleep/command/dictation/mixed) — driven by `sketchybar_bridge.py` |
| `mic` | Shows 🔇 only while mics are muted (driven by `mic-toggle`) |
| `clock` | Rightmost anchor — time-of-day glyph + 12-hour time |

(`huekey.sh` is still in `plugins/` but is not wired into the bar.)

---

## Custom Scripts (bin/)

About 130 scripts on PATH, plus 30 scene scripts in `bin/pixel-scenes/`. Run any directly. `robots` symlinks to the Rust binary in `~/.cargo/bin`. Full list: `ls ~/.dotfiles/bin/`.

**AI / CIPHER / fleet**
| Script | Does |
|--------|------|
| `ai-commit` | 3 conventional commit messages via Claude, pick with fzf (also lazygit `a`) |
| `morning-ritual` | CIPHER reads Things + calendar + git + Obsidian, ranks 12 pomodoros, you multi-select |
| `cipher-daily` | Daily CIPHER wisdom (7am LaunchAgent) |
| `claude-say` | ElevenLabs text-to-speech (falls back to `say`); mutes the mic first, one voice per tmux window, messages queue |
| `claude-statusline` | One-line Claude Code status line that drops low-priority segments instead of wrapping |
| `claude-waiting` | Claude Code hook: flags the tmux pane when Claude is waiting on you |
| `claude-log-ship` | Ship Claude Code fleet event logs to VPS Loki |
| `second-opinion` | Send a diff to the PC, where Codex reviews it read-only and prints findings |
| `brief-pictures` | Morning picture DM: today's charts + one art tile (once a day) |
| `fleet-watch` | tmux 3×3 grid watching subagent panes |
| `chrome-grid` | One Chrome window per URL, auto-tiled |

**computah (Windows GPU box)** — see [dedicated section](#computah--windows-gpu-box)
| Script | Does |
|--------|------|
| `computah` | Drive the PC: wake/status/doctor/render/blender/whisper/demucs/llm/imagine/sd-server/muse/show/… |
| `computah-provision` | Provision the PC (models, services, firewall, Defender exclusions) |
| `computah-check` / `computah-probe` | One-shot health check / vitals cache for the sketchybar widget |
| `pcps` | Run PowerShell on the PC from stdin or a file |
| `pcshot` | Screenshot the PC's interactive desktop → downscaled 1920px JPEG (readable at vision limits) |
| `deskflow-heal` | Self-healing for the Deskflow KVM (four checks, see below) |
| `gpu-llm` | Use the PC's local LLM only if it's already running; never auto-starts it |
| `renders` / `blender-sync` | Browse Blender output / mirror it into `~/Pictures/Blender` |
| `studio-dev` / `studio-turntable` / `studio-words` | Iterate on the 1-bit Blender studio, render turntables, feed it vocabulary |
| `muse-arena` / `muse-cloudinary` | Gather visual inspiration for the art wall |
| `muse-ingredients` / `muse-brainstorm` | Build prompts from Obsidian motifs (`--trace` shows provenance) |
| `muse-lifefeed` / `muse-visualize` | Turn recent posts, commits and vault passages into image subjects |
| `muse-vision` / `muse-push` | Local VLM critique / push screen + notes to the wall |
| `muse-bestof` / `muse-steer` | Best-of-N sketches finished by img2img / steering experiments |
| `muse-taste-*` | The taste model: probe, seed, backfill, weights, and the data behind the PC's taste page |

**Screen tools**
| Script | Does |
|--------|------|
| `show` | Put files/URLs on the second display without stealing focus; auto-grids whatever is open |
| `board` | Numbered briefing wall across the Dell and the PC's 4K; `board clear` takes it down |

**Recording / booth / OBS**
| Script | Does |
|--------|------|
| `booth` | Mise en place for a voiceover take: Logic project on one display, script on the other |
| `studio` | Size-locked Ghostty for terminal demos (9:16 default, `wide`, `greenscreen`, `rec`) |
| `vclip` | Save the vertical backtrack clip right now (behind the floating CLIP button) |
| `obs-automute` | Mutes the mic when OBS enters a BRB / Starting Soon scene |
| `obs-computah-source` | Adds the PC's OBS feed to the iMac's OBS as a scene |
| `obs-defer` | Keeps heavy background jobs off the machine while OBS is open (queue / skip / `drain`) |
| `obs-synccheck` | Measures the rig's real A/V offset (flash + beep); `--apply` sets the mic offset |
| `chat-desk` | Big-type stream chat as a bare Chrome app window |
| `clip` | Turn a recording into captioned 9:16 Shorts (wraps `~/code/stream-clipper`) |
| `name-recordings` | OCR-identify screen recordings (ffmpeg + macOS Vision, zero API tokens) → rename to `YYYY-MM-DD-HHMM-<slug>.mov`; `--apply`, `--llm` (local Qwen slugs) |

**Lights / display / desk**
| Script | Does |
|--------|------|
| `hue` | Hue Bridge v2 CLI (rooms/scenes/on/off/dim) |
| `hue-stream` | 50Hz DTLS Entertainment streaming daemon |
| `flash` / `flash-toast` | Fire a desk flash by hand / the matching tmux toast + silent banner |
| `flash-log` / `flashlog` | Record who caused a flash / show the last N |
| `hue-flash` / `rgb-flash` | One-shot light-flash notifications |
| `desk-event` | Grammar for desk-light event signalling (colors/pulses) |
| `office-lights` | On-air look for the camera (`onair` / `restore` / `status`); one room only |
| `hue-keys` / `huetype` / `huetype-tui` | Keyboard-reactive lighting toggles/config |
| `hue-screen` / `screensync` | Screen → Hue ambient sync |
| `tmux-kb-lights` | Keyboard layer keys glow per tmux window (amber = Claude waiting) |
| `pixel` / `pixel-live` / `pixel-scenes` | ESP32 desk-display control + scenes |
| `pixel-email-count` / `pixel-email-refresh` | Email badge for the desk display |

**System / macOS**
| Script | Does |
|--------|------|
| `theme` / `theme-dark` / `theme-light` | Switch light/dark across the whole stack |
| `appearance-watcher` | React to macOS light/dark changes (2s poll) |
| `relbins` | Install/upgrade CLI tools from official release binaries (Intel) |
| `screenshot-cloudinary` | Auto-upload screenshots to Cloudinary (WatchPaths LaunchAgent) |
| `mic-toggle` | Microphone on/off |
| `btop` | System monitor wrapper |
| `mac-backup` / `laptop-backup` | Desktop backup to the PC / laptop work to R2 (rclone) |
| `mac-stay-reachable` | Keep-awake/reachable helper |
| `tailscale` | Tailscale helper |
| `window-mode-doctor` / `setup-window-mode` | Window-mode (⌥Space snapping) diagnostics + setup |
| `autoplace-train` / `window-habits` | Nightly learner for window autoplace / read-only report of where each app gets snapped |
| `things-bridge` / `things-export` | Push a Things 3 summary (titles, dates, counts) to the VPS / export it as JSON |
| `uptimerobot-sync` / `kuma-push` | Declare uptime monitors here / report a job heartbeat |
| `owner-login` | Open an owner-only VPS app, already logged in |
| `karabiner-ipc-watch` | Watch for the Karabiner IPC stuck-modifier bug |
| `macropad-discover` | Discover/configure macropad |

**Dotfiles / security**
| Script | Does |
|--------|------|
| `dfsync` | Warn on unpushed/unpulled/dirty dotfiles state |
| `dotfiles-verify` / `dotfiles-audit` | Check symlinks / audit integrity |
| `env-sync` | Render secrets from 1Password references into the env files scripts source |
| `env-from-clipboard` / `gh-secret-from-clipboard` | Move a key from the clipboard into an `.env` or `gh secret set`, never echoed |
| `gh-credential` | git credential helper that finds `gh` on Intel or Apple Silicon |
| `leak-scan` | Look for leaked values in gists/npm/HIBP/wayback/GitHub search |
| `security-scan-cron` | Weekly launchd security scan wrapper |
| `canary` | Document beacons that phone home and raise an alert |

**tmux / content / misc**
| Script | Does |
|--------|------|
| `tmux-scratch-toggle` / `tmux-project-layout` | Scratch popup / recreate a project's pane layout |
| `tmux-reading-mode` / `tmux-focus-color` | Center the active pane (prefix+Z) / status color by time in the window |
| `nvp` | Launch the experimental `nvim-pack` config |
| `obs` | Obsidian CLI wrapper (not OBS) |
| `pub` / `send-to-canvas` | Publishing / send to Canvas |
| `connectology-push` | Create a Connectology network from a d3-style JSON graph |
| `music` | Music helper (TP-7 pipeline) |
| `cheatsheets` | Cheatsheet panel + standalone sheets |
| `playtest-subway` | Subway Builder playtest launcher |
| `vps` | Open the VPS in its own dark Ghostty window |
| `usage-summary` / `usage-analyze` / `usage-log` | Usage stats + logging |

---

## computah — Windows GPU Box

`computah` drives a Windows PC (9800X3D / RX 9070 XT) over SSH, with a LAN→Tailscale fallback. It's the render farm, local-LLM host, and art-wall engine.

```bash
computah status                 # reachable? load? disk?
computah wake / sleep           # power on (WoL) / suspend
computah doctor                 # full health check + auto-heal
computah harden-wol             # run once if wake dies after a full shutdown
computah imagine "a fox" 1024x1024   # one FLUX.2-klein image on the GPU
computah sd-server start        # keep the model HOT (skip per-render reload)
computah llm on/off             # local Qwen server on :8085
computah ask "<prompt>"         # one answer from the local LLM, then give the GPU back
computah muse-loop              # the weird art wall from your screen + notes
computah render <file>          # encode a video on the PC, result lands back beside it
computah whisper / demucs <file>     # transcribe / split stems on the GPU
computah show <file|url>...     # put things on the PC's 4K monitor, auto-gridded
computah screenshot             # the real Windows desktop → ~/screenshots/computah
computah stream-ready / stream-done  # one-click streaming setup and teardown
computah gpu status             # who holds the GPU and why
computah run "<cmd>"            # any remote command
```

More verbs (`blender`, `mount`, `obs`, `rgb`, `stream`, `grid`, `muse`, `renders`, `scanner-worker`…) are in the header of `bin/computah`.

**`doctor`** checks models, Defender exclusions, firewall rules, wake timers, the preview server, the Deskflow KVM, GPU leases and the PC-side services, and fixes the small reversible things itself. A scheduled run (`computah doctor --scheduled`, daily) sends one alert if anything is still wrong and stays silent when healthy. It never wakes a sleeping PC.

**`sd-server`** keeps FLUX.2-klein resident on the 9070 XT so `imagine`/`muse-loop` skip the multi-minute per-render model load — after startup each render is sampling-only. It runs under the PC's service supervisor and refuses to start while a game is running or a GPU lease is held; endpoint `http://<pc>:1234/sdapi/v1/{txt2img,img2img}`.

**Games win.** Anything GPU-heavy (`llm on`, `ask`, `show`, sd-server) refuses or backs off while a game is running.

**`deskflow-heal`** keeps the software KVM between the Mac and the PC alive. Quiet and idempotent, it logs only when it acts:
1. Kills a respawned Universal Control (it steals the screen edge before Deskflow), but only if you have Universal Control disabled.
2. Warns if NordVPN is connected (it blocks the KVM port); never disconnects it.
3. If the server core isn't listening, quits the Deskflow GUI and relaunches it (a GUI that outlives its crashed core never restarts it).
4. If the Mac is listening, the PC is awake on the LAN, and no client has connected for a few minutes, restarts the hung client on the PC. At most once every 15 minutes.

**Reverse channel:** on the PC, `tomac <file>` drops a file into `~/Desktop/from-computah` here (robot SSH key + Mac authorized_keys).

---

## Ambient Lighting & Hardware

The room is an output device. The flash grammar is a traffic light: **white = FYI**, **green = done**, **yellow = needs you**, **red = error**; countable pulses = urgency. `lib/desk-flash-patterns.json` is the source of truth.

| Piece | What it is |
|-------|------------|
| `hue` | Python CLI for Hue Bridge v2 (rooms/scenes/on/off/dim/scene) |
| `hue-stream` (bin) + `hue-stream/node/` | Node daemon streaming the Hue Entertainment API over DTLS at ~50Hz (localhost:9999 UDP) |
| `hue-stream/screen-sync.py` | Samples the iMac display → UDP zones to the daemon (~24 FPS, saturation-weighted so it's not grey mush) |
| `hue-stream/pc-rgb-sync.py` | Samples the display → OpenRGB on the Windows PC (Aura header + DualSense lightbar) |
| `hue-stream/pc-rgb-effect.py` | Persistent wave/breathe/pulse RGB on the PC; mirrors to desk lights; handles flash signals via `/tmp/pc-rgb-flash` |
| `hue-stream/latency-test.py` | Measures UDP-pulse → bulb-visible latency via webcam |
| `desk-event` + `lib/desk-flash-patterns.json` + `lib/flash-lib.sh` | Unified event-flash grammar (fyi/done/needs/error patterns + scope) shared across the flash scripts |
| `flash` / `flashlog` | Fire a flash by hand / see who fired the last ones |
| `office-lights` | The on-air look, switched on when OBS launches and restored when it quits |
| Hammerspoon hue-key | Every keypress → spatial color burst; typing streaks walk HCL red→indigo (see [Hammerspoon](#hammerspoon)) |

**Pixel canvas** — an ESP32-S3 desk display (self-healing via `pixel find`):
- `lib/pixelkit.py` — placement-aware drawing primitives (text/rect/circle/line + VULPES palette)
- `lib/pixelfx.py` — pixel-by-pixel scene entrances (dither, implode…)
- `lib/pixel-pick.py` — weighted-random scene selector (time-of-day, email/agent signals, Spotify, favorites, never repeats)
- `lib/pixel-host.sh` — device discovery (env override → cache → default `10.0.0.103`)
- `pixel` runs every 5 min and `pixel-email-refresh` hourly (LaunchAgents)

Gotchas worth knowing: rapid DTLS cycling wedges the bridge (power-cycle it); keyboard-reactive lights are toggled with `hue-keys on/off`, and on a fresh machine they react until you turn them off; one room is excluded from light streaming in code, not config; alerts flash real rooms, so don't test them unannounced.

---

## Talon Voice Control

A 20-file voice layer in `talon-overrides/`, symlinked into `~/.talon/user/talon-overrides`. Hands-free control of tmux, Ghostty, git, and navigation.

| Area | Files | Highlights |
|------|-------|------------|
| Tmux | `tmux.talon`, `terminal_pop.talon` | window/pane nav, splits, zoom, layouts; pop = Enter |
| Terminal | `ghostty.talon`, `terminal_commands.talon` | line editing (wipe/chomp/cancel), history, `run claude/codex/neovim/...`, `go <project>`, safe git verbs |
| Editor | `cursor.talon`, `custom_keys.talon`, `macos_nav.talon` | find/replace, splits, tabs, macOS nav |
| Mic & audio | `mic_toggle.py`, `audio_switch.py`, `voyager_speech_toggle.{talon,py}` | file-signal mic toggle; auto-switch to AirPods when present; a keyboard key toggles speech on/off |
| Sleep | `deep_sleep_media.py` | in QuickTime and Final Cut only the long wake phrase works, so playing back your own voice can't wake Talon |
| Feedback | `ejfox_subtitles.py`, `mode_line.py`, `sketchybar_bridge.py` | custom right-aligned subtitles; fires `sketchybar --trigger talon_state` on mode change |
| Misc | `nato_alphabet.py`, `vocabulary.talon-list`, `usage_logging.py`, `settings.talon`, `apps.py` | NATO spelling, custom vocab, usage logging, tmux-prefix = `ctrl-a` |

---

## Hammerspoon

`hammerspoon/init.lua` (auto-reloads on save, 250ms debounce). It does the window work now:

1. **Window snapping.** Karabiner only captures the leader: **⌥Space**, then a key, calls `hs -c "windowSnap('left')"`, and Hammerspoon moves the window through the Accessibility API (so macOS Secure Event Input can't starve it).

   | Key (after ⌥Space) | Action |
   |---|---|
   | `h` `j` `k` `l` / arrows | Halves; repeat when already there to throw the window to the next display |
   | `⇧h` `⇧j` `⇧k` `⇧l` | Quarters; repeat toggles the other half |
   | `space` | Maximize |
   | `⇧space` | Centered golden-ratio float |
   | `u` | Undo the last snap (or autoplace) |
   | `?` | Toggle the floating cheatsheet panel |
   | `esc` / `q` | Leave window mode |

2. **Autoplace.** New windows of listed apps snap to a home slot by themselves, filling slots in order (Safari: iMac left, iMac right, then the second display). A nightly learner (`autoplace-train`) mines the window log and adjusts the homes. Disable with `touch ~/.config/autoplace-disabled`.
3. **Window logging.** A snapshot of the arrangement every 5 minutes and after every snap, to `usage-logs/windows/`.
4. **Hue-key bursts.** Every keypress sends a UDP pulse to the hue-stream daemon. Keys within 0.8s form a streak that walks hue through HCL colorspace (deep red → deep indigo over ~2400 keys), with per-key spatial falloff. Toggled with `hue-keys on/off`; the tap is fully stopped while off.
5. **OBS reveal.** When OBS finishes a recording, Finder reveals it on the second display.
6. **Sub-modules:** `computah-audio.lua` (menu-bar mute/volume for the PC), `studio.lua` (keeps the recording terminal's size), `obs-lights.lua` (on-air lights + automute with OBS), `vclip.lua` (floating CLIP button), `tp7-unpublish.lua` (one-click unpublish for a jam).

Broken? Read the banner at the top of `~/.config/karabiner/WINDOW-MODE.md` and run `window-mode-doctor` — do **not** restart Karabiner daemons piecemeal.

---

## Scheduled Jobs (LaunchAgents)

Eight launchd jobs are tracked in `LaunchAgents/` and symlinked into `~/Library/LaunchAgents` by `sync-dotfiles.sh`:

| Job | Runs | Schedule |
|-----|------|----------|
| `com.ejfox.cipher-daily` | `bin/cipher-daily` | 7:00 AM daily |
| `com.ejfox.brief-pictures` | `bin/brief-pictures` | 8:02 AM daily |
| `com.ejfox.pixel-canvas` | `bin/pixel random` | every 5 min (+ at load) |
| `com.ejfox.pixel-email` | `bin/pixel-email-refresh` | hourly (+ at load) |
| `com.ejfox.motd-precache` | `.startup.sh` | every 30 min (warms the MOTD) |
| `com.ejfox.blender-sync` | `bin/blender-sync` | every 15 min; skipped while OBS is open |
| `com.ejfox.autoplace-train` | `bin/autoplace-train` | 4:30 AM daily |
| `com.ejfox.screenshot-cloudinary` | `bin/screenshot-cloudinary` | WatchPaths on `~/screenshots` |

`LaunchAgents/ejfmbp/` holds one laptop-only job (`homebrew-logrotate`). Machine-specific jobs (the computah doctor, Deskflow heal, backups, the weekly security scan) live in `~/Library/LaunchAgents` and are not versioned here.

---

## LLM / CIPHER Integration

AI is a suggestion engine — you always pick the final action. Everything speaks in the CIPHER persona (`.llm-persona.txt`): terse, William Gibson meets Unix philosophy, dry wit, glyphs `◆ ◇ ○ ●` not emoji.

| Feature | Flow |
|---------|------|
| `ai-commit` | Stage → Claude drafts 3 conventional messages → fzf picker with diff preview → you choose |
| `morning-ritual` | Gather Things + calendar + git + Obsidian + history → CIPHER ranks 12 pomodoros → multi-select top 3 → added to Things |
| startup oracle | A few lines of poetry drawn from real activity, regenerated hourly in the background; the shell only shows the cache |
| `second-opinion` | A different model reviews the diff before work is called done |
| fleet observability | `claude-log-ship` pushes Claude Code hook events to VPS Loki (`job=claude_fleet`) |

The AI scripts run through the `claude` CLI on subscription auth, so most need no API key. Outputs are cached to avoid redundant calls.

---

## Usage Logging

Shell, nvim, tmux, window, and voice activity is logged to JSON Lines for later pattern analysis.

```bash
usage-summary              # today's stats
usage-summary 2025-01-20   # a specific day
usage-analyze              # last 7 days
usage-analyze 30           # last 30 days
```

Logs: `~/.local/share/usage-logs/{shell,nvim,tmux,windows,talon,claude,presence,pixel,lights}/YYYY-MM-DD.jsonl`. Sources: `lib/shell-usage-logging.zsh` (zsh hooks), `lib/tmux-usage-logging.conf` (tmux hooks), `.config/nvim/lua/plugins/usage-logging.lua`, Hammerspoon (windows), and `talon-overrides/usage_logging.py`. `usage-log <stream> <event> k=v…` is the write helper. Good for finding alias candidates, hot files, slow commands, and workspace patterns.

---

## Helper Libraries (lib/)

| File | Purpose |
|------|---------|
| `shell-usage-logging.zsh` | zsh preexec/precmd hooks → usage JSONL |
| `tmux-usage-logging.conf` | tmux hooks → usage JSONL |
| `pixelkit.py` | Placement-aware drawing primitives for the ESP32 display (VULPES palette) |
| `pixelfx.py` | Pixel-by-pixel scene entrances |
| `pixel-pick.py` | Weighted-random scene selector (signals + no-repeat) |
| `pixel-log.py` | `pixel log`: read back what the canvas showed |
| `pixel-host.sh` | Device discovery for the pixel canvas |
| `pixel-fonts/` | OCR-A / OCR-B / MICR fonts for the canvas |
| `briefdata.py` / `sitestats.py` / `rhythm.py` | Data for pixel scenes: the morning brief, ejfox.com stats, daily rhythms from the usage logs |
| `music-cli/` | TP-7 recorder pipeline (sync, a privacy gate before any upload, whisper, memos into week notes, jam publishing); a tracked mirror of the live copy |
| `mystical-symbols.sh` | Symbol library: moon phases, I Ching hexagrams, planetary hours, glyphs (used by the MOTD and the menu-bar clock) |
| `flash-lib.sh` | Shared helpers for the flash scripts |
| `desk-flash-patterns.json` | The event-flash grammar shared across the lighting scripts |

---

## Claude Code Config

The repo vendors part of the Claude Code setup under `.claude/`: a `settings.json` snapshot (not the live file), `skills/` (`delegate-to-human`, `buy-domain-and-deploy`), `ROBOT-HUMAN-PROTOCOL.md`, and `agents/` — 17 personas (an archivist, a stage manager, a standards editor, a nvim tutor…). `sync-dotfiles.sh` links the whole `agents/` directory into `~/.claude/agents`, so a new persona file is live as soon as it's saved.

The status line is `bin/claude-statusline`; `claude-waiting` marks tmux panes where Claude is waiting on you. `.config/claude/mcp-servers/` holds a small tmux MCP server.

---

## Other Configs

| Tool | Path | Notes |
|------|------|-------|
| Atuin | `.config/atuin/config.toml` | Shell history search; minimal config, no theme variants |
| Bat | `.config/bat/` | `--theme=auto:system`; vulpes + Catppuccin tmThemes |
| Karabiner | `.config/karabiner/` | The ⌥Space leader + `WINDOW-MODE.md` (snapping runbook) |
| Yazi | `.config/yazi/` | File manager; light/dark vulpes themes + plugins |
| Btop | `.config/btop/` | System monitor; `btop-{dark,light}.conf` |
| Fzf | `.config/fzf/` | `theme-{dark,light}.sh` → `current.sh` symlink |
| Lazygit | `.config/lazygit/` | AI-commit custom commands (`a`/`<c-a>`/`<c-b>`), light/dark themes |
| Zsh | `.config/zsh/themes/` | Prompt palettes, light and dark |
| nvim-pack | `.config/nvim-pack/` | The `nvp` experiment (see [Neovim](#neovim-setup)) |
| OBS | `obs/` | Scene collection, profile, MIDI bindings, LUTs; symlinked live, device ID scrubbed by a git filter |
| Irssi | `.irssi/themes/cracked.theme` | IRC theme (config itself gitignored — holds server passwords) |
| Obsidian | `.obsidian-config/` | Tracked hotkeys/community-plugins/snippets (vault content stays in iCloud) |

---

## Secrets & Security

**Never commit secrets.** They live in 1Password. `bin/env-sync` renders `env.op` and `claude-wiki.op` (only `op://` references, safe to commit) into `~/.env` and `~/.claude-secrets` (gitignored, `chmod 600`, sourced by `.zshrc`). The plain files exist because launchd jobs can't answer a biometric prompt.

- **Pre-commit hook** (`.githooks/pre-commit`, enabled by `sync-dotfiles.sh`) scans staged changes for leaked secrets and blocks the commit — you'll see `◆ Scanning for secrets... ✓ No secrets detected`.
- **This repo is public** (`github.com/ejfox/dotfiles`). `.irssi/config` is explicitly gitignored because it can hold plaintext server passwords — only the theme file is tracked.
- **`leak-scan`** (gists/npm/HIBP/wayback/gh-search) and a local secret scanner run weekly via a launchd job that lives outside this repo. GitHub push protection is on.
- **Keys move by clipboard, never as command arguments:** `env-from-clipboard`, `gh-secret-from-clipboard`.
- Keys previously scrubbed from history were rotated; see the incident note in `CLAUDE.md`.

---

## Customization

**Add aliases:** edit `~/.dotfiles/.zshrc`, then `source ~/.zshrc`. Machine-specific ones go in `hosts/<hostname>.zsh`.

**Add nvim plugins:** create `.config/nvim/lua/plugins/your-plugin.lua`:
```lua
return {
  { "author/plugin-name", event = "VeryLazy", opts = {} },
}
```

**Change tmux bindings:** edit `~/.dotfiles/.tmux.conf`, then `tmux source ~/.tmux.conf`.

**Add a cheatsheet entry:** edit `cheatsheet/cheatsheet.toml`, run `cheat gen`. Never edit the generated `.html` directly.

**Enable Ghostty shaders:** drop `custom-shader = ...` lines into `~/.config/ghostty/config.local` (gitignored), then `Cmd+Shift+R`.

**Swap the theme:** `theme-dark` / `theme-light`, or just `theme` to re-sync to the OS.

**Upgrade a CLI tool on Intel:** `bin/relbins status`, then `bin/relbins install`. After upgrading yazi, lazygit or fzf, check the vulpes theme files: yazi and lazygit silently ignore renamed keys.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Neovim plugins not loading | `:Lazy sync` |
| Vue `gd` returns 0 results | `:checkhealth vim.lsp` — need both `vtsls` and `vue_ls` attached |
| LSP not working | `:checkhealth vim.lsp` and `:Mason` for missing servers |
| Treesitter parsers fail to build | `brew install tree-sitter-cli` |
| Tmux changes not applying | `tmux source ~/.tmux.conf` |
| Theme looks wrong in light/dark | run `theme` (re-syncs everything) |
| Ghostty shaders not showing | they're off by default — add to `config.local`, `Cmd+Shift+R` |
| "Command not found" | ensure `/opt/homebrew/bin` **and** `~/.local/bin` are on PATH |
| `brew upgrade` is compiling LLVM | stop it; on Intel use `bin/relbins` |
| A secret is missing in a new shell or job | `bin/env-sync --check`, then `bin/env-sync` |
| Window snapping broke | read `~/.config/karabiner/WINDOW-MODE.md`, run `window-mode-doctor` (never restart Karabiner piecemeal) |
| Cursor won't cross to the PC | `deskflow-heal -v` (it says what it found and fixes it) |
| Node "stuck" after upgrade | bump the pinned node version in `.zshrc` |
| Symlinks broken | `cd ~/.dotfiles && ./sync-dotfiles.sh` |
| Desk lights wedged | power-cycle the Hue bridge (DTLS lockup) |
| Everything broken | `dotfiles-verify` runs the full checklist |

---

## Docs

| File | What's in it |
|------|-------------|
| `CLAUDE.md` | Rules and gotchas for AI pair-programming (git, PATH, secrets, Intel upgrade rules) |
| `docs/CLAUDE-NOTES.md` | Per-feature history and setup logs; read the relevant section before changing a feature |
| `docs/tips.txt` | Complete keybinding cheatsheet (shown randomly on startup) |
| `docs/WORKFLOWS.md` | Advanced CLI pipelines (obs, pub, llm) |
| `docs/STARTUP_DOCS.md` | How the startup script and morning ritual work |
| `docs/THEME-SYSTEM.md` | Light/dark theme architecture, recovery, known cruft |
| `docs/TMUX-READING-MODE.md` | The `C-a Z` reading mode |
| `docs/FOXMEDIA.md` | foxmedia CLI: screenshot auto-upload to Cloudflare R2 + Obsidian logging |
| `docs/HISTORY.md` | A narrative history of this repo, 2019–2025 (an essay, not a changelog) |
| `.config/karabiner/WINDOW-MODE.md` | Window-mode runbook |
| `hammerspoon/README.md` | Window snapping, autoplace, OBS reveal, hue-key |
| `obs/README.md` | The OBS rig |
| `cheatsheet/README.md` | The `cheat` TUI and TOML schema |

---

*Minimal config, maximum velocity. Everything glows.*
