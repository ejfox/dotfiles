# Window snapping — ⌥Space leader

New machine? Run **`setup-window-mode`** (in `bin/`), it wires everything up
and prints the manual GUI steps (Accessibility, DriverKit approval).

## How it works

```
⌥Space + direction (Karabiner leader, karabiner.json)
        → /usr/local/bin/hs -c "windowSnap('left')"
        → windowSnap() in init.lua (Accessibility API, secure-input-immune)
```

Authoritative doc, history, and debugging runbook:
[`../.config/karabiner/WINDOW-MODE.md`](../.config/karabiner/WINDOW-MODE.md).
Rule of thumb when it "does nothing": open **Karabiner-EventViewer** and read
what the keyboard actually emits before touching anything else.

## Keys (press ⌥Space, then…)

| Key | Action |
|---|---|
| `h` `l` `k` `j` / arrows | half on that side; repeat = throw to next display |
| `space` | maximize |
| `⇧h` `⇧l` `⇧k` `⇧j` | quarter on that side; repeat toggles the pair |
| `⇧space` | golden-ratio centered float (again = 1/φ²) |
| `u` | undo last snap |
| `esc` / `q` / 2 s | exit mode |

## Keyboard note (Ergodox / Voyager)

The leader matches **option or control** + space. Your ZSA boards must have a
thumb key emitting `left_option` (configure in Oryx). The 2026-06 outage was
exactly this: the board sent `left_option` while the rule wanted `control`.
