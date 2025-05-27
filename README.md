# ◆ Dotfiles

Minimalist terminal configuration focused on functional beauty and distraction-free computing.

## Core Philosophy
- **Geometric symbols** throughout interface (◆ ◇ ○ ▪ ─)
- **Theme-agnostic** design (works in light/dark mode)  
- **Zen mode** for deep focus
- **Modern CLI tools** replacing legacy commands

## Installation

```bash
git clone https://github.com/ejfox/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./sync-dotfiles.sh
```

## What's Included

### 🔧 **Shell & Terminal**
- `.zshrc` - Modern shell with LLM integration + modern CLI aliases
- `.startup.sh` - AI-powered MOTD with contextual information
- `.zen-mode.sh` - Toggle minimal UI mode across all apps
- `.p10k.zsh` - Minimal Powerlevel10k prompt configuration

### ⌨️ **Terminal Multiplexer**
- `.tmux.conf` - Geometric status indicators, subtle active pane underline
- Vim-style navigation, zen mode integration

### 🎨 **Applications**
- `ghostty/` - Terminal with opacity + blur effects
- `nvim/` - LazyVim with minimal statusline + zen mode
- `yazi/` - Clean file manager without color distractions
- `btop/` - System monitor with transparent background

### 🔄 **Development**
- `.gitconfig` - Clean git setup with LFS support
- `.npmrc` - Node package manager configuration
- Modern CLI replacements: `lsd`, `bat`, `dust`, `duf`, `btop`

### 📱 **Legacy Support**
- `.bash_profile`, `.zprofile` - Shell environment setup
- `.hyper.js` - Hyper terminal configuration (backup)

## Key Features

- **Active pane indicator**: Subtle `─` underline (theme-agnostic)
- **Smart status**: Geometric symbols for window counts (⚌ ☰ ⚍)  
- **LLM integration**: Context-aware terminal greetings
- **Workflow tools**: Things CLI, Obsidian, canvas-sketch integration
- **One-command zen**: `zen` toggles minimal mode everywhere

## Modern CLI Tools

| Old | New | Purpose |
|-----|-----|---------|
| `ls` | `lsd` | Better directory listings |
| `cat` | `bat` | Syntax highlighting |
| `du` | `dust` | Disk usage visualization |
| `df` | `duf` | Disk free visualization |
| `top` | `btop` | System monitoring |

---

*Every pixel serves a purpose. Maximum functionality, minimum distraction.*