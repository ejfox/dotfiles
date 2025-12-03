# 🎯 Complete Claude Code + Nvim Setup

You now have the EXACT setup from the Xata article - but better!

## What You Got

### 1. **Inline Ghost Text** ✨
- Copilot shows suggestions as gray ghost text at your cursor
- `Tab` to accept - old school, comfortable
- `Alt-]` / `Alt-[` to cycle through suggestions
- NO annoying popup menus

### 2. **Hot Reload System** 🔥
**Instant file reloads when Claude Code edits:**
- Filesystem watcher using Neovim's native `fs_event` API
- Watches your entire project directory
- Reloads visible buffers automatically
- Won't reload if you have unsaved changes (safe!)

**Triggers:**
- When Claude Code saves files
- When you switch back to nvim (FocusGained)
- When cursor is idle (CursorHold)
- File changes in `.git/` directory

### 3. **Auto-Refreshing Diffview** 🔍
**Review Claude Code changes in real-time:**
- `<leader>gd` - Open git diff view
- Automatically refreshes when Claude Code commits
- Watches `.git/` directory for changes
- Side-by-side diffs with inline editing

### 4. **Copy Code with Path** 📋
**Visual mode selections:**
- `<leader>yr` - Copy with relative path
- `<leader>ya` - Copy with absolute path

**Pastes like:**
```
src/components/Button.tsx:42-55
\`\`\`tsx
<your code here>
\`\`\`
```

Claude Code immediately knows the file + line numbers!

## Files Created

```
~/.config/nvim/lua/
├── plugins/
│   ├── copilot-inline.lua          # Inline ghost text
│   ├── nvim-cmp-lean.lua           # LSP completions only
│   └── claude-code-workflow.lua    # Diffview + reload
└── custom/
    ├── directory-watcher.lua       # Filesystem watcher
    ├── hotreload.lua               # Auto-reload system
    └── git-diff-hotreload.lua      # Diffview auto-refresh
```

**Old files backed up:**
- `copilot.lua.backup`
- `nvim-cmp.lua.backup`

## Activation

**Restart nvim or run:**
```vim
:Lazy sync
:qa
```

Then reopen nvim - everything will be active!

## Test It

1. **Ghost text:**
   - Start typing in a file
   - Gray suggestion should appear
   - Press `Tab` to accept

2. **Hot reload:**
   - Open a file in nvim (left pane)
   - Ask Claude Code to edit it (right pane)
   - Watch it auto-reload in nvim (magic! ✨)

3. **Diffview:**
   - `<leader>gd` to open diff
   - Should show all Claude Code changes
   - Auto-refreshes as Claude commits

4. **Copy with path:**
   - Select some code (visual mode)
   - `<leader>yr` to copy
   - Paste in Claude Code pane

## Keybindings Summary

### AI Completion
- `Tab` - Accept ghost text
- `Ctrl-Right` - Accept word
- `Ctrl-l` - Accept line
- `Alt-]` / `Alt-[` - Cycle suggestions
- `Ctrl-]` - Dismiss
- `Alt-Enter` - Open panel (3 suggestions)

### Git/Diff
- `<leader>gd` - Open diffview
- `<leader>gh` - File history
- `<leader>gc` - Close diffview
- `]c` / `[c` - Jump changes (in diff)

### Copy Code
- `<leader>yr` - Yank with relative path
- `<leader>ya` - Yank with absolute path

### LSP (Popup)
- `Ctrl-n` / `Ctrl-p` - Navigate completions
- `Ctrl-Space` - Trigger manually
- `Enter` - Accept

## Architecture

**Inline AI:** Copilot ghost text (fast, line-level)
**Chat AI:** Avante (`<leader>aa` for Claude chat)
**LSP:** nvim-cmp (types, functions, buffer words)
**Agent:** Claude Code in tmux pane (big refactors)

## Philosophy

> You code manually. Tab accepts suggestions.
> Claude Code handles architecture.
> Diffview shows you everything.

## Troubleshooting

**No ghost text showing:**
```vim
:Copilot status
:Copilot enable
```

**Files not reloading:**
```vim
:lua print(vim.inspect(require('custom.hotreload')))
```

**Diffview not refreshing:**
```vim
:DiffviewOpen
:lua require('custom.git-diff-hotreload').setup()
```

## Sources

Based on:
- [Configuring Neovim for Coding Agents](https://xata.io/blog/configuring-neovim-coding-agents) by Richard Gill
- [diffview.nvim](https://github.com/sindrets/diffview.nvim) by sindrets
- [The (lazy) Git UI You Didn't Know You Need](https://www.bwplotka.dev/2025/lazygit/)

---

**You're ready to code!** 🚀

Manual coding in nvim (left) + Claude Code agent (right) = Perfect workflow
