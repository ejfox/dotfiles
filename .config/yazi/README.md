# Yazi Configuration

Terminal file manager with minimal design, fuzzy search, and bookmarks.

## Installation

```bash
# Yazi is configured via ~/.dotfiles/.config/yazi/
# Plugins auto-install on first launch

yazi --clear-cache     # Clear old plugins
yazi                   # Plugins auto-install, open file manager
```

## Plugins Installed

### Core Plugins
- **diff** - Compare files side-by-side with `d` key
- **glow** - Preview markdown with syntax highlighting
- **git** - Show git status next to files
- **ouch** - Archive handling (zip, tar, 7z compress/extract)

### New Additions
- **fzf** - Fuzzy file search within yazi
  - `Ctrl-f` - Activate fuzzy search
  - Search across hidden files, ignores `.git` and `node_modules`
  - Navigate results with `hjkl` or arrows
  - `Enter` to open selection

- **bookmarks** - Quick directory bookmarks (like harpoon for filesystem)
  - `Ctrl-a` - Add current directory to bookmarks
  - `Ctrl-b` - Toggle bookmark list
  - `b+1/2/3/4/5` - Jump to bookmarked directories
  - Useful for project directories, frequently visited folders

## Core Keybindings

### Navigation
| Keybinding | Action |
|-----------|--------|
| `k` / `j` | Up / down files |
| `h` / `l` | Parent / child directory |
| `g` then `h` | Go to home |
| `g` then `c` | Go to config |
| `/` | Search filename |
| `?` | Search content |

### File Operations
| Keybinding | Action |
|-----------|--------|
| `i` | Enter (open file) |
| `o` | Open with default app |
| `O` | Open with specific app |
| `y` | Copy file |
| `x` | Cut file |
| `p` | Paste file |
| `d` | Delete file |
| `a` | Create file |
| `A` | Rename file |
| `u` | Undo last action |

### Selection & Bulk Operations
| Keybinding | Action |
|-----------|--------|
| `Space` | Toggle select current file |
| `Ctrl-a` | Select/deselect all |
| `:` then command | Run bulk operation on selected |

### New Plugin Keybindings
| Keybinding | Action |
|-----------|--------|
| `Ctrl-f` | Fuzzy find files (fzf.yazi) |
| `Ctrl-b` | Toggle bookmarks menu (bookmarks) |
| `Ctrl-a` | Add current dir to bookmarks |
| `b+1` through `b+5` | Jump to bookmarks 1-5 |
| `d` | Compare files (diff.yazi) |

### Archive Operations (ouch.yazi)
| Keybinding | Action |
|-----------|--------|
| `c` then `a` | Compress selected files |
| `c` then `e` | Extract archive |

### Git Status (git.yazi)
- Files show git status indicator
- Green = added/modified
- Red = deleted/untracked
- Purple = staged

## Configuration Files

### `yazi.toml` - Main config
```toml
[manager]
ratio = [1,3,4]           # Sidebar:main:preview ratio
show_hidden = false       # Hide dotfiles by default
sort_by = "mtime"        # Sort by modification time
sort_dir_first = true    # Directories first
linemode = "mtime"       # Show mod time in list
show_symlink = true      # Display symlink targets

[preview]
max_width = 1200         # Max preview width
max_height = 1200        # Max preview height
wrap = "no"             # Don't wrap long lines
image_delay = 10        # 10ms image loading delay

[plugin]
[plugin.fzf]
fd_args = "--hidden --follow --exclude=.git --exclude=node_modules"
fd_format = "{full_path}"

[plugin.bookmarks]
auto_load = true        # Load bookmarks on startup
```

### `keymap.toml` - Custom keybindings
- All custom plugin keybindings defined here
- Can be extended with additional commands

### `theme.toml` / `theme-light.toml` - Colors
- Catppuccin Mocha (dark) - pure blacks
- Catppuccin Latte (light) - light backgrounds
- 100+ file type icons with colors
- Matches nvim color scheme

### `package.toml` - Plugin dependencies
```toml
[[plugin.deps]]
use = "DreamMaoMao/fzf"
use = "DreamMaoMao/bookmarks"
# ... other plugins
```

## Workflows

### Finding a file quickly
```
1. Press: Ctrl-f
2. Type: filename or pattern
3. Results appear with fzf interface
4. Press: Enter to open selection
```

### Bookmarking a project
```
1. Navigate to project directory
2. Press: Ctrl-a (add bookmark)
3. Confirm bookmark name
4. Later: Press b+1 (or relevant number) to jump
```

### Extract an archive
```
1. Cursor on: .zip / .tar.gz / .7z file
2. Press: c then e
3. Files extract to current directory
```

### Compare file differences
```
1. Select: first file (Space)
2. Select: second file (Space)
3. Press: d (diff)
4. Side-by-side comparison appears
```

## Layout

- **Left sidebar** (1 unit): Directory tree
- **Main panel** (3 units): File list with git status + mod time
- **Preview pane** (4 units): File preview (syntax highlighting, images, markdown)

## Display Features

- **File icons**: Nerd font icons for 100+ file types
- **Git indicators**: Status badges from git.yazi
- **Syntax highlighting**: For code files via bat
- **Markdown preview**: Via glow plugin
- **Image preview**: Inline in preview pane
- **Transparent theme**: Light mode matches terminal background

## Tips

### Quick directory navigation
```bash
# Bookmark your most-used directories:
# Projects: Ctrl-a
# Config: Ctrl-a
# Documents: Ctrl-a

# Later jump with:
# b+1, b+2, b+3
```

### Efficient file finding
```
# If you remember partial filename:
Ctrl-f → type: part-of-name → Enter

# If searching in subdirs:
Ctrl-f → type: dir/pattern → navigate results
```

### Copy file paths
```
1. Open file in yazi
2. Use: Ctrl-c (copy path)
3. Paste in terminal/nvim with Cmd-v
```

### Bulk operations
```
1. Select files: Space (multiple times)
2. Press: y (copy) or x (cut) or d (delete)
3. Navigate to destination
4. Press: p (paste)
```

## Performance

- **Load time**: < 100ms
- **Plugin sync**: Auto-on startup
- **History**: Remember last position
- **Auto-preview**: Delayed 10ms to avoid lag

## Auto-Dark Mode Integration

Yazi themes auto-switch with system appearance:
- System dark → `theme.toml` (Catppuccin Mocha)
- System light → `theme-light.toml` (Catppuccin Latte)

Matches nvim auto-dark-mode.nvim configuration.

## Troubleshooting

**Plugins not showing?**
```bash
yazi --clear-cache
yazi                  # Reinstall plugins
```

**Fzf search not working?**
- Check `fd` is installed: `which fd`
- Verify config in `yazi.toml`: `[plugin.fzf]` section
- Restart yazi

**Bookmarks not saving?**
- Ensure `auto_load = true` in `yazi.toml`
- Check write permissions: `ls -la ~/.config/yazi/bookmarks.lua`

**Colors look wrong?**
- Verify terminal theme is set (light/dark)
- Force refresh: `yazi --clear-cache && yazi`
- Check theme files exist: `theme.toml` + `theme-light.toml`

## Related Documentation

- **Main config**: `yazi.toml`
- **Keybindings**: `keymap.toml`
- **Themes**: `theme.toml` (dark), `theme-light.toml` (light)
- **Plugins**: `package.toml`
- **Shell integration**: `.zshrc` with yazi aliases
- **Nvim integration**: Can launch yazi from nvim with `:!yazi`
