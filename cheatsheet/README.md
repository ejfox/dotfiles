# cheat — ejfox's cheatsheet, one source of truth

`cheatsheet.toml` is the **only** place you edit. It drives two renderers:

```
cheatsheet.toml ──┬── cheat gen ──▶ ~/.dotfiles/.config/cheatsheet.html
                  │                 (the Hammerspoon floating panel, ⌥Space ?)
                  └── cheat      ──▶ ratatui TUI (any terminal / tmux pane)
```

The Hammerspoon panel regenerates from the TOML **every time it opens** (its
toggle runs `cheatsheets gen`, which now runs `cheat gen` first). So a save to
`cheatsheet.toml` is all it takes — both the panel and the TUI update.

## Use

```bash
cheat            # open the TUI
cheat gen        # rebuild the HTML panel from the TOML (also via `cheatsheets gen`)
cheat dump 80    # plain-text render at width 80 (for piping / testing)
cheat help
```

TUI keys: `j/k ↑/↓` scroll · `C-d/C-u` half-page · `g/G` top/bottom ·
`space/b` page · `/` search · `a/n/l` filter all/nvim/lazygit · `q` quit.

## Editing the TOML

Each card is a `[[section]]` with `tone`, `tool`, `badge`, `title`, `open`, and
an ordered `body`.

**App context:** a card with `apps = ["Final Cut Pro"]` (Mac app names, as
`pgrep -x` sees them) jumps to the top, opened and badged "● … open", while
that app is running. The Hammerspoon panel also sets `CHEAT_FRONT` to the app
you were in when you opened it, and that app's card goes first. Logic is in
`src/context.rs`. App cards stay out of `docs/tips.txt` on purpose. Body item shapes:

| write                                        | renders as              |
|----------------------------------------------|-------------------------|
| `{ k = "za", d = "toggle" }`                 | a binding row           |
| `{ k = "za", d = "toggle", hl = true }`      | highlighted (teal)      |
| `{ div = true }`                             | a divider               |
| `{ lbl = "at the cursor" }`                  | sub-group label         |
| `{ n = "prose note" }`                       | narrative line          |
| `{ o = "footnote" }`                         | ↳ footnote line         |
| `{ strat = "header", steps = [ ... ] }`      | strategy callout        |

Inline markup (in `n` / `o` / strat steps):
`` `x` `` → key · `*x*` → emphasis (teal) · `**x**` → bold · `` \` `` → literal
backtick. Literal unicode is fine: `→  ⎵ (leader/space)  ⏎ (return)  — (dash)`.

## Layout

- `cheatsheet.toml`     — source of truth (27 curated cards)
- `templates/shell.html`— the panel chrome (CSS/JS/header/tipbar/tips index),
  extracted byte-for-byte from the original HTML; `{{CARDS}}` is the splice point
- `src/model.rs`        — TOML data model
- `src/inline.rs`       — inline-markup parser (shared)
- `src/html.rs`         — `cheat gen` renderer
- `src/tui.rs`          — the ratatui TUI
- `src/main.rs`         — CLI

## Not covered by the TOML (yet)

- The nvim-only / lazygit-only standalone Safari sheets
  (`.config/nvim/cheatsheet.html`, `.config/lazygit/cheatsheet.html`).
- The auto-generated "full index" + rotating tip bar, which come from
  `docs/tips.txt` (already its own source of truth — left as-is).

## Rebuild the binary

```bash
cd ~/.dotfiles/cheatsheet && cargo build --release
# symlinked at ~/.local/bin/cheat -> target/release/cheat
```

Original HTML backed up at `~/.dotfiles/.config/cheatsheet.html.prewrapper.bak`.
