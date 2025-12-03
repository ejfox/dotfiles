# Claude Code + Nvim Workflow

Ultimate setup for coding manually in nvim with Claude Code in adjacent tmux pane.

## Setup

**Tmux Layout:**
```
┌─────────────────┬─────────────────┐
│                 │                 │
│   Nvim          │  Claude Code    │
│   (manual)      │  (agent)        │
│                 │                 │
└─────────────────┴─────────────────┘
```

**Switch panes:** `Ctrl-h / Ctrl-l` (vim-tmux-navigator)

## AI Completion (Inline Ghost Text)

**Copilot suggestions appear as gray ghost text:**
- `Tab` - Accept full suggestion
- `Ctrl-Right` - Accept one word
- `Ctrl-l` - Accept one line
- `Alt-]` - Cycle to next suggestion
- `Alt-[` - Cycle to previous suggestion
- `Ctrl-]` - Dismiss suggestion

**Open panel for multiple suggestions:**
- `Alt-Enter` - Open Copilot panel (browse 3 suggestions)
- `]]` / `[[` - Jump between suggestions in panel
- `Enter` - Accept selected suggestion
- `gr` - Refresh suggestions

## LSP Completion (Popup Menu)

**For language server completions (types, functions, etc):**
- `Ctrl-n` - Next item
- `Ctrl-p` - Previous item
- `Ctrl-Space` - Trigger completion manually
- `Enter` - Accept completion

## Review Claude Code Changes

**After Claude Code edits files:**
- Files auto-reload when you switch back to nvim
- `<leader>gd` - Open git diff view (see all changes)
- `<leader>gh` - File history for current file
- `<leader>gc` - Close diff view

**In diffview:**
- `]c` / `[c` - Jump between changes
- `Tab` - Cycle through files
- `do` - Obtain (accept) change from other side
- `dp` - Put (apply) change to other side

## Copy Code to Claude Code

**Select code in visual mode, then:**
- `<leader>yr` - Copy with relative path (`src/foo.js:10-15`)
- `<leader>ya` - Copy with absolute path

**Paste into Claude Code pane and it'll know the file + line numbers!**

## Model Selection

**Copilot** (inline ghost text):
- Uses GitHub's model (no selection needed)
- Fast, good for line/function completion

**Avante** (chat in nvim sidebar):
- `<leader>aa` - Ask Claude (opens chat)
- `<leader>ae` - Edit with Claude (refactor)
- `<leader>ar` - Refresh chat
- Model: Claude Sonnet 4 (configured in avante.lua)

## Workflow Tips

1. **Write code manually** in nvim (left pane)
2. **Tab to accept** Copilot suggestions as you type
3. **Ask Claude Code** in right pane for big refactors
4. **Switch back to nvim** → files auto-reload
5. **`<leader>gd`** to review what Claude changed
6. **Accept or reject** changes in diffview

## Disable AI if needed

**Turn off Copilot temporarily:**
```vim
:Copilot disable
:Copilot enable
```

**Check status:**
```vim
:Copilot status
```

---

**Philosophy:** You code manually (Copilot helps with lines). Claude Code handles big refactors. Diffview lets you review everything.
