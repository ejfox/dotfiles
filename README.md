# ejfox's dotfiles

Terminal-first development environment optimized for speed-of-thought computing. Everything is fuzzy-searchable, keyboard-driven, and designed to get out of your way.

## Quick Start

```bash
git clone https://github.com/ejfox/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./sync-dotfiles.sh
```

**Dependencies** (install via homebrew):
```bash
brew install neovim tmux zsh fzf ripgrep fd bat lsd zoxide
brew install --cask ghostty
```

## What's Here

```
~/.dotfiles/
├── .zshrc              # Shell config (aliases, PATH, prompt)
├── .tmux.conf          # Terminal multiplexer
├── .config/
│   ├── nvim/           # Neovim (LazyVim-based)
│   ├── ghostty/        # Terminal emulator
│   ├── yazi/           # File manager
│   └── ...
├── bin/                # Custom scripts
└── tips.txt            # Cheatsheet (shown randomly on startup)
```

---

## Philosophy

### Why These Tools?

| Tool | Why Not the Alternative |
|------|------------------------|
| **Neovim** | VS Code is slow and not terminal-native |
| **Tmux** | Terminal tabs don't persist across restarts |
| **Zsh** | Fish isn't POSIX-compatible, Bash lacks features |
| **Ghostty** | Fast (Zig), GPU-accelerated, good defaults |
| **LazyVim** | Sensible defaults, easy to customize, well-maintained |

### Core Ideas

**Fuzzy find everything.** Don't navigate folder trees—search. `vs` finds files, `vg` searches content, `o` opens notes.

**Pane-based workflow.** One tmux session, multiple panes visible at once. Editor, terminal, logs, server—all on screen together.

**Popup workflows.** `C-a g` opens lazygit floating over your panes. Do your thing, close it, layout untouched.

**Single-buffer file management.** oil.nvim opens directories as editable buffers. Delete a line = delete the file. No sidebar.

**Same keys everywhere.** `C-h/j/k/l` moves between vim splits AND tmux panes seamlessly.

---

## Daily Workflow

### Opening Files

```bash
v              # Open neovim
vs             # Fuzzy find files (with preview)
vg             # Grep file contents, jump to match
o              # Fuzzy find Obsidian notes
r              # Recent files across all projects
```

### File Management (oil.nvim)

From any file in neovim:
```
-              # Open parent directory
<CR>           # Open file/directory
(edit line)    # Rename file
(delete line)  # Delete file
g.             # Toggle hidden files
```

This is the key insight: the filesystem IS the buffer. Vim motions work on files.

### Tmux Essentials

```
C-a            # Prefix key (not C-b, easier to reach)
C-h/j/k/l      # Move between panes (works in vim too!)
C-a g          # Lazygit popup
C-a S          # Scratch terminal popup
C-a Space      # tmux-thumbs (copy any text with hints)
C-a -          # Split pane vertically
C-a _          # Split pane horizontally
```

### Git

```bash
C-a g          # Lazygit popup (preferred)
gs             # git status
ga             # git add
gc             # git commit
gp             # git push
```

In lazygit, press `a` for AI-generated commit messages (uses Claude).

### LSP Navigation (Neovim)

```
gd             # Go to definition
gr             # Go to references
K              # Hover documentation
<leader>ca     # Code actions
<leader>rn     # Rename symbol
```

---

## Key Config Decisions

### Tmux: C-a prefix instead of C-b

`C-b` requires moving your hand off home row. `C-a` is right there. To go to beginning of line (normally C-a in shell), use `C-a a`.

### Neovim: Native LSP, not wrapped in Telescope

Many configs route `gd` through fuzzy finders. This config uses `vim.lsp.buf.definition` directly. Fewer layers = faster and more reliable.

### oil.nvim instead of file tree sidebar

File trees (NERDTree, neo-tree) eat screen space and encourage "browsing." oil.nvim encourages "acting"—you're always in a buffer using vim motions.

### vim-tmux-navigator

Same `C-h/j/k/l` keys navigate both vim splits and tmux panes. No mental overhead about which context you're in.

### Lazy loading everything

Neovim starts in <100ms despite 40+ plugins. Everything loads on first use, not startup.

---

## LLM Integration

AI is used as suggestion engine, not autopilot:

- **ai-commit**: Generates 3 commit message options, you pick one
- **morning-ritual**: Suggests pomodoros ranked by priority, you select
- **startup oracle**: Daily I Ching-style wisdom based on your tasks

All outputs are cached to avoid slow/expensive repeated API calls.

---

## Customization

### Adding aliases

Edit `~/.dotfiles/.zshrc`, then `source ~/.zshrc`.

### Adding Neovim plugins

Create a file in `~/.config/nvim/lua/plugins/your-plugin.lua`:

```lua
return {
  {
    "author/plugin-name",
    event = "VeryLazy",  -- lazy load
    opts = {
      -- config here
    },
  },
}
```

### Changing tmux bindings

Edit `~/.dotfiles/.tmux.conf`, then `tmux source ~/.tmux.conf`.

---

## Secrets

API keys go in `~/.env` (gitignored), never in dotfiles:

```bash
# ~/.env
export ANTHROPIC_API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."
```

The `.zshrc` sources this file automatically.

---

## Troubleshooting

**Neovim plugins not loading**: Run `:Lazy sync`

**Tmux changes not applying**: Run `tmux source ~/.tmux.conf`

**LSP not working**: Check `:LspInfo` and `:Mason` for missing servers

**"Command not found"**: Ensure `/opt/homebrew/bin` is in PATH

---

## File Reference

| File | Purpose |
|------|---------|
| `.zshrc` | Shell aliases, PATH, prompt config |
| `.tmux.conf` | Tmux keybindings, plugins, appearance |
| `.config/nvim/` | Neovim config (LazyVim + custom plugins) |
| `.config/ghostty/` | Terminal appearance, shaders |
| `.startup.sh` | MOTD shown on terminal open |
| `bin/` | Custom scripts (ai-commit, morning-ritual, etc) |
| `tips.txt` | Cheatsheet, shown randomly on startup |
| `CLAUDE.md` | Context for AI assistants working on this repo |

---

## Other Docs

- `CLAUDE.md` - Detailed notes for AI pair programming
- `tips.txt` - All keybindings and shortcuts
- `WORKFLOWS.md` - Advanced CLI pipelines (obs, pub, llm)
- `STARTUP_DOCS.md` - How the startup script works

---

*Minimal config, maximum velocity.*
