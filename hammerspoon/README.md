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
| `?` | toggle floating translucent cheatsheet panel (drag by top edge) |
| `esc` / `q` / 2 s | exit mode |

## Autoplace — newborn windows snap themselves home (added 2026-07-15)

**If a new Safari/Mail/Chrome/Spotify window just moved on its own — this is
why.** A week of window logs showed these apps get manually snapped to the
same slot almost every time, so `init.lua` (section "Autoplace") now does it
automatically for **newly created windows only**:

| App | Home slot |
|---|---|
| Safari | iMac left-half |
| Mail | iMac right-half (compose windows exempt) |
| Google Chrome | Dell top-half |
| Spotify | Dell top-half |

It never moves existing windows, never touches float apps (Messages, Discord,
Things, 1Password…), and skips windows already at their home slot.

- **Undo one placement**: `⌥Space u`
- **Disable instantly**: `touch ~/.config/autoplace-disabled` (rm to re-enable)
- **Remove forever**: delete the "Autoplace" section in `init.lua`
- **Audit**: placements log as `trigger:"autoplace"` in
  `~/.local/share/usage-logs/windows/*.jsonl`

## OBS reveal — finished recordings pop up on the Dell (added 2026-10-04)

**If Finder just opened `~/Movies` at the bottom of the Dell — this is why.**
When OBS finishes a recording in `~/Movies` (record stop, replay-buffer save,
Aitum `-vertical`), Finder reveals the new file, selected, in the bottom 30%
of the portrait DELL. "Finished" = an OBS-named file (`2026-10-04 10-43-09.mov`,
`Replay …`, `…-vertical…`) that hasn't been written to for 4s; when the main
and `-vertical` files finish together you get one window, on the main file.
`-synced` copies, clipper output and `obs-synccheck` test takes never trigger
it, and reloading the config never re-reveals an old take.

- **Disable instantly**: `touch ~/.config/obs-reveal-disabled` (rm to re-enable)
- **Trigger by hand**: `hs -c "obsReveal('/Users/ejfox/Movies/<file>.mov')"`
- Dell unplugged → Finder still reveals the file, just doesn't get moved

## Keyboard note (Ergodox / Voyager)

The leader matches **option or control** + space. Your ZSA boards must have a
thumb key emitting `left_option` (configure in Oryx). The 2026-06 outage was
exactly this: the board sent `left_option` while the rule wanted `control`.
