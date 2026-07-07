# Retrospective: Hammerspoon window-mode vs. Divvy

> ⚠️ **SUPERSEDED 2026-06-27 — current status in `~/.config/karabiner/WINDOW-MODE.md`.**
> The secure-input analysis below is still correct and worth reading. But the Karabiner+Rectangle
> hybrid it recommends was *built and works*; the later breakage was a wedged virtual HID from
> daemon-thrashing, fixed by a reboot — not anything in this file.

_Dev note — 2026-06-27. Written after a long, frustrating debugging session._

## The honest summary

Divvy worked seamlessly for years. We replaced its window-snapping with a
hand-rolled Hammerspoon **`hs.eventtap`** modal (leader chord → direction keys).
It has been intermittently dying, with no error, in ways that are scary because
window-snapping is load-bearing for EJ's daily workflow. This is a reliability
regression. The flailing was in the architecture choice, not the user.

## What actually went wrong (root causes, in order found)

1. **Hammerspoon wasn't running.** No auto-launch. Fixed: `hs.autoLaunch(true)`
   + confirmed in login items. (Real, but only the first layer.)

2. **Chord confusion.** Code was bound to **⌥Space (Option+Space)**; EJ's muscle
   memory is **Ctrl+Space** (Divvy's old chord). Pressing Ctrl+Space just typed a
   literal space. Rebound leader to **⌃Space** at `init.lua:300` and updated the
   doc comment at `init.lua:131`.

3. **THE REAL KILLER — macOS Secure Event Input starves the eventtap.**
   - A `CGEventTap` (which is what `hs.eventtap` is) receives **zero** key events
     while *any* app has **secure input** enabled — and the tap still reports
     `isEnabled() == true`. Silent, total deafness.
   - Observed live: secure-input holder bounced from `loginwindow` (PID 186) →
     **Safari** (PID 782). Safari turns on secure input whenever a **password
     field is focused** (login page, autofill, even a backgrounded tab). A diag
     tap logging every keyDown captured **nothing** while Safari held it.
   - Karabiner was investigated and **cleared** — it only does Caps→Esc, double-
     left-shift→Ctrl+A, double-right-shift→mic-toggle. It does NOT touch
     Space/Control and is not the culprit.

4. **Watchdog gap.** The health-check at `init.lua:348` only restarts a tap when
   `isEnabled()` is `false`. The secure-input failure leaves the tap
   enabled-but-starved, so the 30s self-heal sails right past it and never fires.

## The architectural lesson

**Why Divvy/Rectangle "just work":** they register global hotkeys via Carbon
`RegisterEventHotKey` (the window-server hotkey registry), which is **not**
starved by secure input the way a raw `CGEventTap` is. Our modal was built on the
one Hammerspoon primitive that IS vulnerable.

**Hammerspoon has the robust path too:** `hs.hotkey` and `hs.hotkey.modal` use
`RegisterEventHotKey` under the hood. A leader+direction modal rebuilt on
`hs.hotkey.modal` would keep the exact same UX but survive secure input. The raw
eventtap was an avoidable choice.

## The options going forward

- **A. Go back to a real window manager for the load-bearing job.**
  Rectangle Pro is **already installed** (it's in login items — a modern Divvy).
  Bind Ctrl+Space-style snapping there. Keep Hammerspoon for the delightful custom
  stuff only (hue-key lights, typing streaks). Lowest risk, highest reliability.
  Recommended if "it must never flake again" is the priority.

- **B. Rebuild window-mode on `hs.hotkey.modal`** (drop the `hs.eventtap`).
  Keeps everything in one config, keeps the bespoke multi-display cycling UX, and
  should fix the secure-input starvation. Moderate effort, some residual risk
  (sleep/wake hotkey quirks exist but are rarer/recoverable).

- **C. Keep the eventtap but add a secure-input watcher** that pops an alert
  naming the culprit app ("⚠ Safari is holding secure input — shortcuts are
  deaf"). This does NOT fix the deafness (the OS won't allow it) — it only makes
  the mystery visible. Band-aid, not a cure.

## Immediate state at end of session

- Hammerspoon running, auto-launch on.
- Leader rebound to Ctrl+Space, config reloaded.
- Window-mode currently dead because **Safari is holding secure input** — clears
  by focusing Safari's address bar (Cmd+L, Esc) or closing the tab with a focused
  login field.
- Diagnostic `diagTap` was left installed in the running HS session (not in the
  config file) — it disappears on next reload/restart.

## Recommendation

Lead with **A** for the daily-driver snapping (reliability EJ can trust), and
optionally do **C**'s watcher in Hammerspoon as an early-warning system. Reserve
**B** for when there's appetite to invest in the bespoke version again.

## RESOLUTION — 2026-06-27 (shipped)

Went with **A**, but solved the one thing A seemed to cost us — the
**Ctrl+Space-THEN-direction** muscle memory, which Rectangle Pro can't do natively
(it has no leader/prefix-key feature). The fix is a hybrid, and crucially **both
layers live below the CGEventTap layer, so secure input can't starve either one:**

- **Rectangle Pro** does the actual snapping. Already configured with a vim scheme:
  - `⌃⌥H / ⌃⌥L` — left / right half
  - `⌃⌥K / ⌃⌥J` — top / bottom half
  - `⌃⌥M` — maximize
  - `⌃⌥⌘O / ⌃⌥⌘U` — next / previous display
- **Karabiner-Elements** provides the leader. New rule in
  `~/.config/karabiner/karabiner.json` ("Window mode: Ctrl+Space leader → Rectangle
  Pro"): `Ctrl+Space` sets a `winmode` variable (and swallows the keystroke so
  macOS's input-source switcher never fires). While `winmode==1`,
  `h/j/k/l/m/space/o/u` emit the matching Rectangle `⌃⌥` chord; `esc`/`q` exit. The
  mode auto-exits after **900 ms** of inactivity and **each direction re-arms it**,
  so sustained `Ctrl+Space ← ← ←` cross-display repeats still work.

**Hammerspoon window-mode was deleted** (`init.lua` 367 → 170 lines). The
`windowLeaderTap` / `hs.eventtap` window path is gone entirely; only `hueKeyTap`
(hue lights) still uses an eventtap, and that's non-load-bearing — if secure input
starves it, lights just don't react; your windows are unaffected. Old config
backed up to `/tmp/init.lua.bak` (ephemeral).

**Why this is the right shape:** the leader UX EJ has in his fingers is preserved
exactly, but the two parts that have to be reliable (catching the keys, moving the
window) now run on the same secure-input-immune primitives that made Divvy "just
work" for years. The eventtap — the one fragile primitive — was removed from the
critical path, not patched.
