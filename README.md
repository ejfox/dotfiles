# ejfox's dotfiles

Terminal-first development environment optimized for speed-of-thought computing. Everything is fuzzy-searchable, keyboard-driven, voice-controllable, and wired into ambient lighting, a Windows GPU box, and a wall of custom telemetry. It is designed to get out of your way — and occasionally to glow pink at you.

This is a big config. 383 tracked files, 75 scripts, a Rust cheatsheet TUI, 24 Neovim plugin configs, a voice-control layer, an ambient-lighting protocol, and a persistent-model art wall. The README is long on purpose; use the table of contents.

**Three ways to read this:**
- **New Mac?** Start at [Quick Start](#quick-start-new-mac) and follow the setup.
- **Guest computer?** Jump to the [Keybinding Reference](#keybinding-reference) to reload your muscle memory.
- **Spelunking?** The [Repository Layout](#repository-layout) map links to every subsystem's deep-dive section below.

Host machine: **Intel iMac** running macOS. A few choices (Ghostty shaders off by default, node/torch pins) exist specifically because this is x86_64 hardware.

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
brew install neovim tmux zsh fzf ripgrep fd bat lsd zoxide atuin lazygit yazi jq
brew install --cask ghostty
```

### 2. Clone and sync

```bash
git clone https://github.com/ejfox/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./sync-dotfiles.sh
```

`sync-dotfiles.sh` pulls latest (stashing local changes if needed), symlinks every dotfile and `.config/` directory into place, wires the Talon overrides into `~/.talon/user/`, points lazygit at its `~/Library/Application Support` location, and enables the pre-commit security hook (`git config core.hooksPath .githooks`).

### 3. Set up secrets

```bash
# ~/.env is gitignored and sourced automatically by .zshrc
cat > ~/.env << 'EOF'
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export HUE_BRIDGE_IP="..."
export HUE_APP_KEY="..."
export HUE_CLIENT_KEY="..."
# add other keys as needed
EOF
chmod 600 ~/.env
```

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

**Popup workflows.** `C-a g` opens lazygit floating over your panes. Do your thing, close it, layout untouched. Same for `C-a K` (yazi) and `C-a S` (scratch).

**Single-buffer file management.** oil.nvim opens directories as editable buffers. Delete a line = delete the file. No sidebar.

**Same keys everywhere.** `C-h/j/k/l` moves between vim splits AND tmux panes seamlessly (vim-tmux-navigator).

**AI as suggestion engine, not autopilot.** Commit messages, morning priorities, diagnostics — AI proposes, you choose. The persona is CIPHER (`.llm-persona.txt`).

**The computer is multi-sensory.** Lights react to typing, the menu bar coaches you, a desk display shows telemetry, and voice drives the terminal. Signal, not noise: attention events glow hot pink; FYIs glow teal.

**Tracked sources, gitignored live state.** Theme flips swap symlinks/copies that are gitignored, so switching light↔dark never dirties the repo.

| Tool | Why |
|------|-----|
| **Neovim** | Terminal-native, LazyVim on nvim 0.11+, ~24 custom plugin configs |
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
v              Open neovim
vs             Fuzzy find files (with preview)
vg             Grep file contents, jump to match
o              Fuzzy find Obsidian notes
r              Recent files across all projects
c              Clear terminal + refresh
l / ll / la    lsd directory listings
cheat          Cheatsheet TUI (ratatui)
cheatsheet     Open HTML cheatsheet panel
theme          Re-sync all tools to current light/dark mode
```

### Tmux

```
C-a            Prefix key (not C-b)
C-h/j/k/l      Move between panes (works in vim too)
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

**Navigation (native LSP, not wrapped in a picker):**
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
<leader>fe     Open project .env
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
<leader>gp     Diff gutter vs PR base (auto-detects via gh)
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

**Focus & misc:**
```
<leader>Z      Zen mode
<leader>up     Prose mode (narrow, no numbers)
<leader>uw     Toggle wrap
<leader>ut     Toggle twilight (dim inactive context)
<leader>sl/st/su/sq   Strudel: launch / toggle play / eval / quit
<leader>yr/ya  Copy selection with relative / absolute path + line range
```

### Git

```
C-a g          Lazygit popup (preferred way to do git)
  a            AI commit — 3 Claude-generated options, pick with fzf
  <c-a>        (alt AI-commit binding)
gs / ga / gc / gp   status / add / commit / push
```

### Talon (voice)

```
mux next/prev/last/left/right/up/down/split/zoom/close   Tmux control
run claude/codex/nvim/lazygit/yazi/btop                  Launch tools
go home/code/dotfiles/projects                           cd shortcuts
git status/log/push/pull                                 Git verbs
wipe line/word/ahead, cancel, clear screen               Line editing
remote next/prev/... (Ctrl-B prefix)                     Nested/remote tmux
```

---

## Repository Layout

```
~/.dotfiles/
├── .zshrc                  # Shell config (~450 lines: aliases, PATH, functions)
├── .zshenv / .zprofile     # zsh env (all invocations) / login-once profile
├── .bash_profile           # minimal, defers to zsh
├── .tmux.conf              # Tmux keybindings, plugins, popups
├── .startup.sh             # Terminal MOTD (oracle, calendar, stats)
├── .zen-mode.sh            # Simple zen-mode toggle
├── .p10k.zsh               # Powerlevel10k prompt theme
├── .llm-persona.txt        # CIPHER personality for AI features
├── .gitconfig / .gitattributes / .gitignore
├── .githooks/pre-commit    # Secret scanner (blocks commits with leaks)
├── hosts                   # /etc/hosts reference
├── .config/                # 180 tracked files across 12 app configs
│   ├── nvim/               # Neovim (LazyVim + 24 plugin configs, 8 colorschemes)
│   ├── ghostty/            # Terminal (config + 54 shaders + themes)
│   ├── sketchybar/         # macOS menu bar (11 plugin scripts)
│   ├── lazygit/            # Git TUI (AI-commit keys, light/dark themes)
│   ├── yazi/ btop/ bat/ fzf/   # File mgr / sysmon / cat / fuzzy — all themed light+dark
│   ├── atuin/              # Shell history
│   ├── karabiner/          # Keyboard remapping + WINDOW-MODE.md
│   ├── claude/ zsh/        # Claude Code statusline + zsh themes
│   ├── minimal-prompt.zsh  # Minimal prompt matching tmux/nvim aesthetic
│   └── cheatsheet.html     # Generated cheatsheet panel (from cheatsheet.toml)
├── bin/                    # 75 custom scripts (see tables below)
├── lib/                    # Shared libraries (usage logging, pixel kit, music-cli)
├── cheatsheet/             # Rust/ratatui cheatsheet TUI — SINGLE source of truth
├── hue-stream/             # Hue Entertainment daemon + PC RGB sync
├── hammerspoon/            # Hue-key bursts + modifier logging + auto-reload
├── talon-overrides/        # 17-file voice control layer
├── LaunchAgents/           # 5 scheduled jobs (cipher-daily, pixel, motd, screenshots)
├── scripts/                # Setup + weekly-review scripts
├── docs/                   # Extended documentation (see Docs table)
├── .obsidian-config/       # Tracked Obsidian hotkeys/plugins/snippets (not vault content)
├── .irssi/themes/          # IRC theme (config itself is gitignored — holds passwords)
├── .claude/                # Vendored Claude Code settings, skills, agents
├── vulpes-reddish2-{dark,light}-tmux.tmux.conf   # tmux theme variants
├── sync-dotfiles.sh        # Symlink installer
└── CLAUDE.md               # AI pair-programming context
```

---

## Shell & Zsh

The shell is the front door. Startup is kept fast by pinning the node path instead of invoking `nvm use` (2.0s → 0.56s shells).

| File | Role |
|------|------|
| `.zshenv` | Runs for **all** zsh invocations (interactive, login, scripts, ssh commands). Minimal, PATH-critical. |
| `.zprofile` | Runs **once per login** session. |
| `.zshrc` | The active config (~450 lines): aliases, functions (`vs`/`vg`/`o`/`r`), PATH, plugin loads, sources `~/.env`, loads usage-logging hooks. Symlinked from `~/.zshrc`. |
| `.bash_profile` | Minimal — defers to zsh for the real config. |
| `.p10k.zsh` | Powerlevel10k prompt theme. |
| `.config/minimal-prompt.zsh` | Alternative minimal prompt matching the tmux/nvim aesthetic. |
| `.startup.sh` | Terminal MOTD shown on open — oracle line, calendar, stats. Also precached by a LaunchAgent so first-open is instant. |
| `.zen-mode.sh` | Simple zen-mode toggle for distraction-free work. |
| `lib/shell-usage-logging.zsh` | `preexec`/`precmd` hooks that log commands, `cd`s, and sessions to JSONL (see [Usage Logging](#usage-logging)). |

Shell sync between machines is origin-only: commit + push from each box. `dfsync` warns at shell start on unpushed/unpulled/dirty state. There is exactly **one** clone (`~/.dotfiles`); the old `~/dotfiles` second clone was deleted (it caused six weeks of drift).

---

## Neovim Setup

Based on [LazyVim](https://www.lazyvim.org/) on Neovim **0.11+**, with **24 custom plugin configs** in `.config/nvim/lua/plugins/`. `init.lua` is a single `require("config.lazy")`. Background auto-switches light/dark with macOS appearance (`auto-dark-mode.nvim`, 1s check). Backgrounds are set to `none` so Ghostty's transparency shows through. Clipboard uses macOS `pbcopy`/`pbpaste` (OSC52 off).

### Plugins

| File | Plugin(s) | Purpose |
|------|-----------|---------|
| `oil.lua` | stevearc/oil.nvim | Filesystem as an editable buffer (replaces the file tree); git status inline |
| `utilities.lua` | vim-tmux-navigator, nvim-surround, conform | `C-hjkl` across vim/tmux; surrounds; prettier formatting |
| `nvim-ufo.lua` | nvim-ufo + promise-async | Treesitter folding with indent fallback; peek folds |
| `nvim-dap.lua` | nvim-dap + dap-ui + nio + virtual-text | Full TS/JS/Vue debugging with inline values |
| `git.lua` | gitsigns + git-conflict + oil-git-status | Diff gutter, diff vs main/PR base, conflict resolution |
| `vue-lsp.lua` | nuxt-goto.nvim + manual vtsls attach | Volar 2.0 hybrid mode for Vue/Nuxt (see below) |
| `svelte.lua` | svelte-language-server + treesitter + conform | Svelte SFC support, organize imports |
| `tailwind.lua` | tailwind-fold.nvim | Folds long Tailwind class strings |
| `strudel.lua` | gruvw/strudel.nvim | Live-code music: buffer ↔ strudel.cc |
| `obsidian.lua` | epwalsh/obsidian.nvim | iCloud vault integration, weekly notes |
| `minimal-telescope.lua` | telescope.nvim | Borderless picker, ripgrep with `--hidden`, `<C-_>` vertical split |
| `minimal-statusline.lua` | lualine.nvim | Custom statusline: context path, modified ◆, copilot, diagnostics, LSP icons |
| `snacks.lua` | folke/snacks.nvim | Dashboard (fox header), statuscolumn, git UI, pickers |
| `statuscolumn-tens.lua` | snacks tweak | Every 10th line shows absolute number in grey |
| `nvim-cmp-lean.lua` | blink.cmp | Completion UI (no border, vulpes colors); Tab reserved for Copilot |
| `copilot-inline.lua` | copilot.lua | Inline ghost-text suggestions; `<Tab>` accept |
| `notifications.lua` | nvim-notify + noice | Compact, fading notifications |
| `focus.lua` | zen-mode + prose mode | `<leader>Z` zen, `<leader>up` prose |
| `theming.lua` | auto-dark-mode + twilight | Colorscheme auto-switch; `<leader>ut` twilight |
| `usage-logging.lua` | custom | Logs editing patterns to JSONL |
| `claude-code-workflow.lua` | plenary | Hot-reload on external file change (Claude Code saves) + copy-with-path |
| `baleia.lua` | baleia.nvim | Renders ANSI color codes in buffers |
| `mini.lua` | (placeholder) | mini.diff/animations come via LazyVim extras + snacks |
| `miranda.lua` | ejfox/miranda.nvim | **Disabled** — daily editing coach; needs `~/.config/miranda/` provisioned |

**Config** (`lua/config/`): `keymaps.lua` (native LSP gd/gr, symbols, git-jump), `options.lua` (Monaspace Krypton 13pt, hybrid numbers, pbcopy clipboard), `diagnostics.lua` (virtual_lines on), `autocmds.lua` (markdown wrap, plugin health check), `lazy.lua` (LazyVim + typescript + vue extras; disables gzip/tar/tohtml/tutor/zip builtins).

### Vue/Nuxt LSP (Volar 2.0 hybrid mode)

Volar 2.0 split into two servers; both must run in `.vue` files:
- **vue_ls** (Volar) — `<template>` and `<style>`
- **vtsls** + `@vue/typescript-plugin` — `<script lang="ts">`

`vue-lsp.lua` manually attaches vtsls to Vue files (LazyVim opts-merge wasn't reliable for this), and `nuxt-goto.nvim` fixes `gd` redirecting to `.d.ts` files. If `gd` returns 0 results, check `:lua print(vim.inspect(vim.lsp.get_clients({bufnr=0})))` — you should see both `vtsls` **and** `vue_ls`.

### Colorschemes

8 vulpes variants in `.config/nvim/colors/`, two naming generations:
- Older: `vulpes_reddish_{dark,light}`, `vulpes_reddish2_{dark,light}`, `vulpes_greenish_{dark,light}` (superseded/alt)
- **Active:** `vulpes-reddishnovember-{dark,light}` — warm reds, transparent bg, auto-switched

---

## Ghostty Terminal

Config: `.config/ghostty/config`. Reload with **`Cmd+Shift+R`**.

| Setting | Value |
|---------|-------|
| Font | MonaspaceKr Nerd Font (italic: MonaspiceRn) |
| Opacity | `0.87`, cell-wise, 20px blur |
| Padding | 0 (flush with sketchybar) |
| Cursor | Block, non-blinking, invert fg/bg |
| Theme | Native OS switch: `light:vulpes-reddishnovember-light,dark:...-dark` |

### Shaders — off by default, opt-in per machine

The `shaders/` directory holds **54** GLSL shaders, but they are **all commented out** in the tracked `config`. Because this is an Intel iMac, the shader stack is left off for fan/thermal relief. Fast machines opt in per-host via `config.local` (gitignored, sourced by `config-file = ?config.local`).

The intended "on" stack (uncomment / drop into `config.local`):
1. `cursor-blaze-vulpes.glsl` — velocity-reactive hot-pink cursor trail (`#ff268c`), teleport detection
2. `bloom-vulpes.glsl` — red-selective glow (only blooms warm pixels)
3. `tft-subtle.glsl` — subtle LCD subpixel effect
4. `vignette-vulpes.glsl` — red-accented vignette

The other ~50 (matrix, CRT, starfield, film-grain, glitch, water…) are there to swap in for fun. Helpers: `audit-ghostty-theme.mjs`, `find-vulpes-greens*.mjs`.

> If bloom is ever enabled, keep UI selections dark-bg + white-text + bold — bright saturated selections bloom into an unreadable smear. The nvim/tmux themes already account for this.

---

## Theme System (light/dark)

One command re-skins the entire stack. `bin/appearance-watcher` polls macOS appearance every **2s** and re-syncs on change; `theme` forces a manual re-sync; `theme-dark` / `theme-light` force the OS mode *and* sync.

Each tool switches by a mechanism that fits it — and the **live** file is always gitignored so flipping never dirties the repo:

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
| Claude Code | `jq` rewrite | `theme` field in the Claude config |

Full architecture, recovery steps, and known cruft: [`docs/THEME-SYSTEM.md`](docs/THEME-SYSTEM.md). If things look broken in either mode, just run `theme`.

---

## Cheatsheet System

The cheatsheet is a **Rust/ratatui** project in `cheatsheet/`, and `cheatsheet.toml` is the **single source of truth** for every keybinding — nvim, lazygit, tmux, Talon, computah, hue, window-mode. Edit the TOML, and both renderers update.

```bash
cheat            # ratatui TUI (j/k scroll, / search, a/n/l filter, q quit) — for tmux panes
cheat gen        # regenerate the HTML panel from the TOML
cheat dump 80    # plain-text render at width 80 (pipes/tests)
cheatsheet       # open the generated HTML panel (Hammerspoon; auto-regens on open)
```

Two renderers, one source:
```
cheatsheet.toml ─┬─→ cheat gen ─→ .config/cheatsheet.html   (Hammerspoon panel)
                 └─→ cheat       ─→ ratatui TUI              (any terminal pane)
```

**TOML schema:** each card has `tone` (`accent`/`primary`/`gold`/`prose`), `tool` (`nvim`/`lazygit`/`both`) for filter buttons, `badge`, and `open` (expanded on load). Body items are keybinding rows, dividers, sub-group labels, narrative lines (`n`), and footnotes (`o`). Inline markup: `` `x` `` = key, `*x*` = teal emphasis, `**x**` = bold.

**Vulpes tokens** (`templates/shell.html`): `--base #ff4d8d` (readable pink — `#e60067` was too dark on black), `--teal #7bf0f9`, `--gold #ffd489`, `--bg #000000`, `--fg #f2cfdf`. Build: `cargo build --release` → symlink to `~/.local/bin/cheat`.

Wiki mirror: <https://archive.ejfox.com/wiki/Cheatsheet>.

---

## Sketchybar (menu bar)

macOS menu bar replacement. Config: `.config/sketchybar/sketchybarrc`, with **11** plugin scripts in `plugins/` (`_lib.sh` is a shared helper).

Layout (left → right):
```
[talon] [mic] [next_event] ......... [foundations] [demos] [posts] [dispatch] [battery] [clock]
```

| Plugin | What it shows |
|--------|---------------|
| `next_event` | Calendar countdown w/ per-meeting colors; CIPHER coach suggests a joyful task when the calendar's clear |
| `battery` | OLED-black bg, fades to red below 50%; hides itself on desktop Macs (no battery) |
| `foundations` | Count + staleness of open 🌞 Foundation dailies; visible only outside work hours |
| `demos` | 4-week dot matrix of recordings in `~/demos` |
| `posts` | 4-week dot matrix from ejfox.com RSS pubDates (15-min cache) |
| `dispatch` | Vault publish state from Dispatch's local JSON cache |
| `talon` | Voice-control mode indicator (sleep/command/dictation/mixed) — driven by `sketchybar_bridge.py` |
| `mic` | Shows 🔇 only while mics are muted (driven by `mic-toggle`) |
| `huekey` | Click to toggle keyboard-reactive desk lights |
| `clock` | Rightmost anchor — time-of-day glyph + 12-hour time |

---

## Custom Scripts (bin/)

75 scripts on PATH. Run any directly. `robots` symlinks to the Rust binary in `~/.cargo/bin`. Full list: `ls ~/.dotfiles/bin/`.

**AI / CIPHER / fleet**
| Script | Does |
|--------|------|
| `ai-commit` | 3 conventional commit messages via Claude, pick with fzf (also lazygit `a`) |
| `morning-ritual` | CIPHER reads Things + calendar + git + Obsidian, ranks 12 pomodoros, you multi-select |
| `cipher-daily` | Daily CIPHER wisdom (7am LaunchAgent) |
| `claude-say` | Text-to-speech with adaptive playback |
| `claude-log-ship` | Ship Claude Code fleet event logs to VPS Loki |
| `fleet-watch` | tmux 3×3 grid watching subagent panes |
| `chrome-grid` | One Chrome window per URL, auto-tiled |

**computah (Windows GPU box)** — see [dedicated section](#computah--windows-gpu-box)
| Script | Does |
|--------|------|
| `computah` | Drive the PC: wake/status/doctor/render/blender/demucs/llm/imagine/**sd-server**/muse/harden-wol |
| `computah-provision` | Provision the PC (models, services, firewall, Defender exclusions) |
| `deskflow-heal` | Idempotent Deskflow KVM keepalive |
| `muse-arena` / `muse-cloudinary` | Gather visual inspiration for the art wall |
| `muse-ingredients` / `muse-brainstorm` | Build prompts from Obsidian motifs (`--trace` shows provenance) |
| `muse-vision` / `muse-push` | Local VLM critique / push screen + notes to the wall |
| `pcshot` | Screenshot the PC's interactive desktop → downscaled 1920px JPEG (readable at vision limits) |

**Lights / display / desk**
| Script | Does |
|--------|------|
| `hue` | Hue Bridge v2 CLI (rooms/scenes/on/off/dim) |
| `hue-stream` | 50Hz DTLS Entertainment streaming daemon |
| `hue-flash` / `rgb-flash` | One-shot light-flash notifications |
| `hue-keys` / `huetype` / `huetype-tui` | Keyboard-reactive lighting toggles/config |
| `hue-screen` / `screensync` | Screen → Hue ambient sync |
| `desk-event` | Grammar for desk-light event signalling (colors/pulses) |
| `pixel` / `pixel-live` / `pixel-scenes` | ESP32 desk-display control + scenes |
| `pixel-email-count` / `pixel-email-refresh` | Email badge for the desk display |

**System / macOS**
| Script | Does |
|--------|------|
| `theme` / `theme-dark` / `theme-light` | Switch light/dark across the whole stack |
| `appearance-watcher` | React to macOS light/dark changes (2s poll) |
| `screenshot-cloudinary` | Auto-upload screenshots to Cloudinary (WatchPaths LaunchAgent) |
| `mic-toggle` | Microphone on/off |
| `btop` | System monitor wrapper |
| `mac-backup` / `mac-stay-reachable` | Backup + keep-awake/reachable helpers |
| `tailscale` | Tailscale helper |
| `setup-window-mode` / `window-mode-doctor` | Window-mode (⌥Space snapping) setup + diagnostics |
| `karabiner-ipc-watch` | Watch for the Karabiner IPC stuck-modifier bug |
| `macropad-discover` | Discover/configure macropad |

**Dotfiles / security**
| Script | Does |
|--------|------|
| `dfsync` | Warn on unpushed/unpulled/dirty dotfiles state |
| `dotfiles-verify` / `dotfiles-audit` | Check symlinks / audit integrity |
| `secret-scan` / `leak-scan` | Secret scanners (git history + live values; gists/npm/HIBP/wayback) |
| `security-scan-cron` | Weekly launchd security scan wrapper |

**tmux / content / misc**
| Script | Does |
|--------|------|
| `tmux-scratch-toggle` / `tmux-project-layout` | Scratch popup / recreate a project's pane layout |
| `obs` / `pub` / `send-to-canvas` | Obsidian utils / publishing / send to Canvas |
| `music` | Music helper |
| `clip` | Turn a recording into captioned 9:16 Shorts (wraps `~/code/stream-clipper`) |
| `cheatsheets` | Open HTML cheatsheets in Safari |
| `playtest-subway` | Subway Builder playtest launcher |
| `vps` | VPS connection utility |
| `usage-summary` / `usage-analyze` / `usage-log` | Usage stats + logging |

---

## computah — Windows GPU Box

`computah` drives a Windows PC (9800X3D / RX 9070 XT) over SSH, with a LAN→Tailscale fallback. It's the render farm, local-LLM host, and art-wall engine.

```bash
computah status                 # reachable? load? disk?
computah wake / sleep           # power on (WoL) / suspend
computah doctor                 # diagnose deskflow / wall / renders
computah harden-wol             # run once if wake dies after a full shutdown
computah imagine "a fox" 1024x1024   # one FLUX.2-klein image on the GPU
computah sd-server start        # keep the model HOT (skip per-render reload)
computah llm on/off             # local Qwen server on :8085
computah muse-loop              # the weird art wall from your screen + notes
```

**`sd-server`** (new) keeps FLUX.2-klein resident on the 9070 XT so `imagine`/`muse-loop` skip the multi-minute per-render model load — after startup each render is sampling-only. A logon scheduled task revives it after reboot; endpoint `http://<pc>:1234/sdapi/v1/{txt2img,img2img}`.

**Reverse channel:** on the PC, `tomac <file>` drops a file into `~/Desktop/from-computah` here (robot SSH key + Mac authorized_keys).

---

## Ambient Lighting & Hardware

The room is an output device. Signal grammar: **hot pink = needs you**, **teal = FYI**, **red = error**, countable pulses = magnitude.

| Piece | What it is |
|-------|------------|
| `hue` | Python CLI for Hue Bridge v2 (rooms/scenes/on/off/dim/scene) |
| `hue-stream` (bin) + `hue-stream/node/` | Node daemon streaming the Hue Entertainment API over DTLS at ~50Hz (localhost:9999 UDP) |
| `hue-stream/screen-sync.py` | Samples the iMac display → UDP zones to the daemon (~24 FPS, saturation-weighted so it's not grey mush) |
| `hue-stream/pc-rgb-sync.py` | Samples the display → OpenRGB on the Windows PC (Aura header + DualSense lightbar) |
| `hue-stream/pc-rgb-effect.py` | Persistent wave/breathe/pulse RGB on the PC; mirrors to desk lights; handles flash signals via `/tmp/pc-rgb-flash` |
| `hue-stream/latency-test.py` | Measures UDP-pulse → bulb-visible latency via webcam |
| `desk-event` + `lib/desk-flash-patterns.json` | Unified event-flash grammar (fyi/done/needs/error patterns + scope) shared across rgb-flash / pc-rgb-effect |
| Hammerspoon hue-key | Every keypress → spatial color burst; typing streaks walk HCL red→indigo (see [Hammerspoon](#hammerspoon)) |

**Pixel canvas** — an ESP32-S3 desk display (self-healing via `pixel find`):
- `lib/pixelkit.py` — placement-aware drawing primitives (text/rect/circle/line + VULPES palette)
- `lib/pixel-pick.py` — weighted-random scene selector (time-of-day, email/agent signals, Spotify, favorites, never repeats)
- `lib/pixel-host.sh` — device discovery (env override → cache → default `10.0.0.103`)
- `pixel` runs every 15 min and `pixel-email-refresh` hourly (LaunchAgents)

Gotchas worth knowing: rapid DTLS cycling wedges the bridge (power-cycle it); keyboard-reactive lights default **off** (roommate-friendly); never touch computah mid-Fortnite.

---

## Talon Voice Control

A 17-file voice layer in `talon-overrides/`, symlinked into `~/.talon/user/talon-overrides`. Hands-free control of tmux, Ghostty, git, and navigation.

| Area | Files | Highlights |
|------|-------|------------|
| Tmux | `tmux.talon`, `terminal_pop.talon` | window/pane nav, splits, zoom, layouts, `mux git/files/scratch` popups |
| Terminal | `ghostty.talon`, `terminal_commands.talon` | line editing (wipe/chomp/cancel), history, `run claude/codex/nvim/...`, `go <project>`, safe git verbs |
| Editor | `cursor.talon`, `custom_keys.talon`, `macos_nav.talon` | find/replace, splits, tabs, macOS nav |
| Mic & audio | `mic_toggle.py`, `audio_switch.py` | file-signal mic toggle; auto-switch to AirPods when present |
| Feedback | `ejfox_subtitles.py`, `mode_line.py`, `sketchybar_bridge.py` | custom right-aligned subtitles; fires `sketchybar --trigger talon_state` on mode change |
| Misc | `nato_alphabet.py`, `vocabulary.talon-list`, `usage_logging.py`, `settings.talon`, `apps.py` | NATO spelling, custom vocab, usage logging, tmux-prefix = `ctrl-a` |

---

## Hammerspoon

`hammerspoon/init.lua` (auto-reloads on save, 250ms debounce). Two jobs:

1. **Hue-key bursts** — every keypress sends a UDP pulse to the hue-stream daemon. Keys within 0.8s form a streak that walks hue through HCL colorspace (deep red → deep indigo over ~2400 keys, L=28 C=95 H=15°→285°), with per-key spatial falloff. Config: `~/.config/hue-key/config.json`. Eventtaps auto-rearm on wake/sleep and via a 30s health check (macOS silences taps after sleep).
2. **Modifier logging** — logs `flagsChanged` transitions to `usage-logs/modifiers/` to hunt the Karabiner 16.1.0 stuck-modifier bug.

**Window snapping is not in Hammerspoon anymore** — macOS Secure Event Input starves `hs.eventtap` in password fields. It moved to Karabiner + Rectangle Pro: **⌥Space** leader → `h/j/k/l`/arrows (halves), `⇧`+keys (quarters), `space` (max), `u` (undo). New Safari/Mail/Chrome/Spotify windows auto-place to mined home slots. Broken? Read `~/.config/karabiner/WINDOW-MODE.md` and run `window-mode-doctor` — do **not** restart Karabiner daemons piecemeal.

---

## Scheduled Jobs (LaunchAgents)

Five launchd jobs in `LaunchAgents/` (load with `launchctl load ~/Library/LaunchAgents/<name>.plist`):

| Job | Runs | Schedule |
|-----|------|----------|
| `com.ejfox.cipher-daily` | `bin/cipher-daily` | 7:00 AM daily |
| `com.ejfox.pixel-canvas` | `bin/pixel random` | every 15 min (+ at load) |
| `com.ejfox.pixel-email` | `bin/pixel-email-refresh` | hourly (+ at load) |
| `com.ejfox.motd-precache` | `.startup.sh` | 9:00 & 10:00 AM (warms the MOTD) |
| `com.ejfox.screenshot-cloudinary` | `bin/screenshot-cloudinary` | WatchPaths on `~/screenshots` |

---

## LLM / CIPHER Integration

AI is a suggestion engine — you always pick the final action. Everything speaks in the CIPHER persona (`.llm-persona.txt`): terse, William Gibson meets Unix philosophy, dry wit, glyphs `◆ ◇ ○ ●` not emoji.

| Feature | Flow |
|---------|------|
| `ai-commit` | Stage → Claude drafts 3 conventional messages → fzf picker with diff preview → you choose |
| `morning-ritual` | Gather Things + calendar + git + Obsidian + history → CIPHER ranks 12 pomodoros → multi-select top 3 → added to Things |
| startup oracle | Daily contextual line on terminal open |
| sketchybar CIPHER coach | Suggests a joyful task when the calendar's clear |
| fleet observability | `claude-log-ship` pushes Claude Code hook events to VPS Loki (`job=claude_fleet`) |

Keys live in `~/.env`. Outputs are cached to avoid redundant calls.

---

## Usage Logging

Shell, nvim, tmux, and keyboard-modifier activity is logged to JSON Lines for later pattern analysis.

```bash
usage-summary              # today's stats
usage-summary 2025-01-20   # a specific day
usage-analyze              # last 7 days
usage-analyze 30           # last 30 days
```

Logs: `~/.local/share/usage-logs/{shell,nvim,tmux,modifiers}/YYYY-MM-DD.jsonl`. Sources: `lib/shell-usage-logging.zsh` (zsh hooks), `lib/tmux-usage-logging.conf` (tmux hooks), `.config/nvim/lua/plugins/usage-logging.lua`, and Hammerspoon (modifiers). Good for finding alias candidates, hot files, slow commands, and workspace patterns.

---

## Helper Libraries (lib/)

| File | Purpose |
|------|---------|
| `shell-usage-logging.zsh` | zsh preexec/precmd hooks → usage JSONL |
| `tmux-usage-logging.conf` | tmux hooks → usage JSONL |
| `pixelkit.py` | Placement-aware drawing primitives for the ESP32 display (VULPES palette) |
| `pixel-pick.py` | Weighted-random scene selector (signals + no-repeat) |
| `pixel-host.sh` | Device discovery for the pixel canvas |
| `music-cli/` | TP-7 recorder import pipeline (libmtp mount, whisper transcription, R2 backup) via launchd |
| `mystical-symbols.sh` | Symbol library: moon phases, I Ching hexagrams, planetary hours, glyphs (used by the MOTD) |
| `desk-flash-patterns.json` | The event-flash grammar shared across the lighting scripts |

---

## Claude Code Config

The repo also vendors the Claude Code setup under `.claude/`: `settings.json` / `settings.local.json`, a `skills/` directory (including `graphify`), `agents/`, and `ROBOT-HUMAN-PROTOCOL.md`. The statusline lives at `.config/claude/statusline.sh`, with MCP server configs in `.config/claude/mcp-servers/`. (The powerline statusline theme itself is configured outside this repo, in `~/.claude/claude-powerline.json`.)

---

## Other Configs

| Tool | Path | Notes |
|------|------|-------|
| Atuin | `.config/atuin/config.toml` | Shell history search; minimal config, no theme variants |
| Bat | `.config/bat/` | `--theme=auto:system`; vulpes + Catppuccin tmThemes |
| Karabiner | `.config/karabiner/` | Key remapping + `WINDOW-MODE.md` (⌥Space snapping runbook) |
| Yazi | `.config/yazi/` | File manager; light/dark vulpes themes + plugins |
| Btop | `.config/btop/` | System monitor; `btop-{dark,light}.conf` |
| Fzf | `.config/fzf/` | `theme-{dark,light}.sh` → `current.sh` symlink |
| Lazygit | `.config/lazygit/` | AI-commit custom commands (`a`/`<c-a>`), light/dark themes |
| Irssi | `.irssi/themes/cracked.theme` | IRC theme (config itself gitignored — holds server passwords) |
| Obsidian | `.obsidian-config/` | Tracked hotkeys/community-plugins/snippets (vault content stays in iCloud) |

---

## Secrets & Security

**Never commit secrets.** API keys go in `~/.env` (gitignored, `chmod 600`), sourced automatically by `.zshrc`.

- **Pre-commit hook** (`.githooks/pre-commit`, enabled by `sync-dotfiles.sh`) scans staged changes for leaked secrets and blocks the commit — you'll see `◆ Scanning for secrets... ✓ No secrets detected`.
- **This repo is public** (`github.com/ejfox/dotfiles`). `.irssi/config` is explicitly gitignored (line 99) because it can hold plaintext server passwords — only the theme file is tracked.
- **`secret-scan`** (git history + live-value rules) and **`leak-scan`** (gists/npm/HIBP/wayback/gh-search) run weekly via a launchd job. GitHub push protection is on.
- Keys previously scrubbed from history were rotated; see `CLAUDE.md` and `docs/HISTORY.md`.

---

## Customization

**Add aliases:** edit `~/.dotfiles/.zshrc`, then `source ~/.zshrc`.

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

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Neovim plugins not loading | `:Lazy sync` |
| Vue `gd` returns 0 results | `:LspInfo` — need both `vtsls` and `vue_ls` attached |
| LSP not working | `:LspInfo` and `:Mason` for missing servers |
| Tmux changes not applying | `tmux source ~/.tmux.conf` |
| Theme looks wrong in light/dark | run `theme` (re-syncs everything) |
| Ghostty shaders not showing | they're off by default — add to `config.local`, `Cmd+Shift+R` |
| "Command not found" | ensure `/opt/homebrew/bin` **and** `~/.local/bin` are on PATH |
| Window snapping broke | read `~/.config/karabiner/WINDOW-MODE.md`, run `window-mode-doctor` (never restart Karabiner piecemeal) |
| Node "stuck" after upgrade | bump the pinned node version in `.zshrc` |
| Symlinks broken | `cd ~/.dotfiles && ./sync-dotfiles.sh` |
| Desk lights wedged | power-cycle the Hue bridge (DTLS lockup) |
| Everything broken | `dotfiles-verify` runs the full checklist |

---

## Docs

| File | What's in it |
|------|-------------|
| `CLAUDE.md` | AI pair-programming context (git rules, secrets, integrations) |
| `docs/tips.txt` | Complete keybinding cheatsheet (shown randomly on startup) |
| `docs/WORKFLOWS.md` | Advanced CLI pipelines (obs, pub, llm) |
| `docs/STARTUP_DOCS.md` | How the startup script and morning ritual work |
| `docs/THEME-SYSTEM.md` | Light/dark theme architecture, recovery, known cruft |
| `docs/FOXMEDIA.md` | foxmedia CLI: screenshot auto-upload to Cloudflare R2 + Obsidian logging |
| `docs/HISTORY.md` | Changelog |
| `hammerspoon/README.md` | Hammerspoon hue-key + window notes |
| `cheatsheet/README.md` | The `cheat` TUI and TOML schema |

---

*Minimal config, maximum velocity. Everything glows.*
