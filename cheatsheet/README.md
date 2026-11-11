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
`space/b` page · `/` search (every tab) · `1-9` or `tab` switch tab
(`n` nvim, `l` git, `a` all) · `q` quit.

## The model: tabs

The sheet is **tabs**, listed in order in `[meta] groups`
(nvim · git · term · voice · pc · desk · make · ops), plus `all`.

- Every card has a `group` and shows only on that tab. Keys `1-9` switch tabs
  in both the panel and the TUI; the panel reopens on the last tab you used
  (`cheatsheet.html#git` forces one).
- On its tab, a card with `open = true` is expanded; the rest are closed
  titles. Keep it to 2-4 open cards per tab: the daily drivers.
- `all` is a closed outline of every card under group headings.
- Search (`/`) always looks across every tab.
- The tips index (`docs/tips.txt`) is filed per tab too, closed, under the
  curated cards. The category → tab map is `CAT_TAB` in `templates/shell.html`;
  unmapped categories only show on `all`.
- One line per description. Detail goes in an `o` footnote. A card whose keys
  are mostly commands (longer than 10 chars) stacks its rows: command on one
  line, description under it.

## Editing the TOML

Each card is a `[[section]]` with `group`, `tone`, `title`, `open`, and an
ordered `body`.

**App context:** a card with `apps = ["Final Cut Pro"]` (Mac app names, as
`pgrep -x` sees them) pins to the top of every tab, badged "● …", while that
app is running. The Hammerspoon panel sets `CHEAT_FRONT` to the app you were
in when you opened it; that app's card goes first and is the only one opened.
Logic is in `src/context.rs`. App cards stay out of `docs/tips.txt` on purpose.
Body item shapes:

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

- `cheatsheet.toml`     — source of truth (47 curated cards in 8 groups)
- `templates/shell.html`— the panel chrome (CSS/JS/tab strip/tip line/tips
  index); `{{TABS}}` and `{{CARDS}}` are the splice points
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
