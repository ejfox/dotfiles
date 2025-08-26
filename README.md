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

## Configuration Coverage

| Application | Config Location | Status | Description |
|------------|-----------------|---------|-------------|
| **Shell (Zsh)** | `.zshrc` (447 lines) | ✅ Modified | Main shell config with Powerlevel10k prompt, aliases, PATH setup |
| **Powerlevel10k** | `.p10k.zsh` | ✅ Active | Terminal prompt theme configuration |
| **Neovim** | `.config/nvim/` | ✅ Modified | LazyVim-based config with custom plugins (vue-nav, snacks, minimal-statusline) |
| **Tmux** | `.tmux.conf` (128 lines) | ✅ Modified | Terminal multiplexer with custom settings |
| **Vim** | `.vimrc` (19 lines) | ✅ Active | Basic vim configuration |
| **Ghostty** | `.config/ghostty/` | ✅ Modified | Terminal emulator with themes directory |
| **Sketchybar** | `.config/sketchybar/` | ✅ Modified | macOS menu bar customization with plugins (including mutagen.sh) |
| **Yazi** | `.config/yazi/` | ✅ Modified | Terminal file manager (yazi.toml, theme.toml, package.toml) |
| **Bat** | `.config/bat/` | 🆕 New | Cat replacement with syntax highlighting |
| **BTerm/BTOp** | `.config/btop/` | ✅ Active | Resource monitor configuration |
| **Atuin** | `.config/atuin/` | ✅ Active | Shell history sync/search tool |
| **Karabiner** | `.config/karabiner/` | ✅ Active | Keyboard customization for macOS |
| **Neofetch** | `.config/neofetch/` | ✅ Active | System info display tool |
| **Claude** | `.config/claude/` | ✅ Active | Claude desktop app settings |
| **HTerm/HTop** | `.config/htop/` | ✅ Active | Process viewer configuration |
| **Wireshark** | `.config/wireshark/` | ✅ Active | Network protocol analyzer |
| **Git** | `.gitignore`, `.gitattributes` | ✅ Active | Version control settings |
| **Docker** | `.docker/config.json` | ✅ Active | Container runtime config |
| **GPG** | `.gnupg/` | ✅ Active | Encryption/signing configuration |
| **VSCode** | `Library/.../Code/User/settings.json` | ✅ Active | Code editor settings |
| **Spectacle** | `Library/.../Spectacle/` | ✅ Active | Window management shortcuts |

---

*Every pixel serves a purpose. Maximum functionality, minimum distraction.*