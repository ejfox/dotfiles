# tmux reading mode

`C-a Z` centers the active pane in a fixed-width column (default 80) in **this
window only**. Other windows are untouched. It's built for reading Claude Code
(which reflows to pane width) on a fullscreen terminal. Press it again to turn it off.

## Usage

| Do | How |
|----|-----|
| Toggle | `C-a Z` |
| Global width | `set -g @reading-width 80` in `.tmux.conf` |
| One window wider (diffs, tables) | `tmux-reading-mode width 100` (no arg prints current) |
| Old global zen (hide status + sketchybar) | `C-a M-z` (`~/.zen-mode.sh`) |

Script: `bin/tmux-reading-mode`. Config: the "Reading mode" block in `.tmux.conf`.

## How it works

- Two blank **padding panes** are split left and right of the pane, and the
  window's borders are drawn as spaces (`pane-border-lines spaces`,
  `pane-border-status off`). Typing into the pads is disabled (`select-pane -d`),
  and they're marked with `@reading-pad 1` and title `reading-pad`.
- Each pad runs `while tmux has -t <pane>; do sleep 3; done`, so if the reading
  pane exits, the pads close themselves within 3 s.
- **Multi-pane or zoomed window:** the pane is `break-pane`d into its own window
  right after the original (`-a -t origin`), with the same name. Toggle-off joins
  it back next to its old neighbor, reapplies the saved layout string and restores
  zoom. If the neighbor is gone or moved, the pane stays in its own window.
- State lives in window options (`@reading`, `@reading-pane`, `@reading-left/right`,
  `@reading-origin/layout/anchor/before/zoomed`) and is cleared on toggle-off.

## Hooks (`.tmux.conf`)

| Hook | Why |
|------|-----|
| `window-resized[50]` | refit the column. Not `client-resized`, which misses `window-size latest` client switches. Gated on `#{@reading}` |
| `after-select-pane[1]` | bounce focus off a pad (`h/l`, `M-N`, mouse, vim-tmux-navigator) with `select-pane -l`. `[0]` is usage-log |
| `pane-mode-changed[1]` | a mouse drag on a pad would enter copy mode there; cancel it |
| `@resurrect-hook-post-save-layout` | `tmux-reading-mode resurrect-scrub <file>` drops pad panes from saves so restores don't bring them back as empty zsh shells |

## Why 80

Claude Code hard-wraps at the pane width and has no max-width setting (open
request anthropics/claude-code#96372). It also adds a gutter (`⏺ ` ≈ 2 cols, tool
results ≈ 5, diffs ≈ 10–12), so prose at 80 is about 77 columns. That's the top
of the 45–75 measure (Bringhurst, ~66 ideal; Baymard 50–75), and monospace lines
read physically longer. Try 72 for pure prose; use `width 100` per window for diffs.

## Gotchas (tmux 3.6a)

- `display -t <missing pane>` silently falls back to the current pane. Use
  `has -t` or `list-panes -a | grep -qx` to check whether a pane exists.
- `break-pane` without `-t` lands in the most recently used session, which may
  be a different one.
- Anything run from a hook or `run-shell` must exit 0. A final false
  `[[ ]] && ...` makes tmux show "returned 1" in the pane.
- `show -wv` on an unset user option logs "invalid option". Use `show -wqv`.
  Window user options don't inherit from the global ones, so fall back by hand.
- A window-scoped `after-select-pane` hook masks the global one, which would kill
  usage-log. Add hooks as new indexes of the global array instead.
- `-t #{...}` inside a hook body isn't format-expanded, hence `select-pane -l`.
- `select-pane -d -T x` silently drops the title. Set the title in a separate call.
- resurrect's saved command for a pane is its *child* process (`sleep 3`), so
  the pad loop can't be the scrub marker. The title is.
- A failed command aborts the rest of a `\;` chain, so `fit` resizes each pad
  in its own call.

## Known edges

- Splitting a pane inside a reading window leaves the extra pane there after
  toggle-off.
- `C-a z` zooms the reading pane to full width (expected).
- Each toggle logs ~6 pad events to usage-log (`pane_split`/`select`/`exit`).
  Filter on `pane_start_command` if it matters.
