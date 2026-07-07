# Handoff: Ctrl+Space window-mode → Rectangle Pro (UNFINISHED)

> ⚠️ **SUPERSEDED 2026-06-27 — read `~/.config/karabiner/WINDOW-MODE.md` first.**
> Correction: the config is valid and *works* (it fired at 10:46). The real failure was a
> **wedged DriverKit virtual HID** from restarting Karabiner daemons too many times → stuck
> modifiers + complex_mods not firing. **Fix = reboot, not daemon-poking.** Disregard this
> file's "edits aren't reaching Karabiner" theory; that was stale.

_2026-06-27. Written after flailing and getting fired. Read this before touching anything._

## TL;DR

EJ wants **Ctrl+Space THEN a direction** (h/j/k/l = halves, space = fill) to snap
windows — the Divvy/old-Hammerspoon muscle memory. The plan was: **Karabiner does
the leader, Rectangle Pro does the snap.** Rectangle works. The Karabiner leader
got into a state where **config edits stopped reaching the running daemon**, and I
burned 5+ failed user tests chasing it instead of isolating the layers first. It
is currently **NOT WORKING** and left in a **debug state** (tracing + no timeout).

## VERIFIED FACTS (measured, not guessed)

- ✅ **Rectangle Pro is installed, running, and has Accessibility.** Windows move.
- ✅ **The URL scheme works 100%**, confirmed by measuring window frames before/after:
  - `open "rectangle-pro://execute-action?name=left-half"` (also `right-half`,
    `top-half`, `bottom-half`, `maximize`). All move the focused window.
  - This is the most reliable trigger we have. It bypasses hotkeys entirely.
- ✅ **The Karabiner leader DID fire** at one point: with fresh config, pressing
  Ctrl+Space logged `STEP1-leader-fired` to `/tmp/kbn-debug.log` three times. So
  the rule *can* work and Karabiner *was* grabbing the keyboard.
- ❌ After later edits, the trace went **empty** — Ctrl+Space stopped firing the
  rule. The on-disk config is CORRECT (verified), so the problem is that **edits
  aren't reaching the running Karabiner**, not the config content.

## THE LIKELY ROOT CAUSE OF THE LOOP

`karabiner_cli --select-profile 'Default profile'` when that profile is **already
selected appears to be a no-op** — it does NOT force a reload. So edits 2..N never
got applied; Karabiner kept running stale config while I "reloaded" into the void.

Then I `launchctl kickstart -k`'d all Karabiner agents (incl.
`Karabiner-Core-Service-rev2`). Logs showed transient `core_service_client
connect_failed: Permission denied` then reconnected. **UNKNOWN whether the
kickstart broke the keyboard grab.** That's the first thing to check.

## TWO CANARY TESTS THAT WILL UNBLOCK THIS (need human fingers — do these FIRST)

I should have run these on minute 1 instead of minute 60. They isolate the layers:

1. **Caps Lock → Escape?** (simple_modification, independent of my rule)
   - Acts as Escape → Karabiner IS grabbing the keyboard; problem is my rule/reload.
   - Toggles caps light → **kickstart broke the grab** → fully quit & reopen
     `Karabiner-Elements.app`, re-approve Input Monitoring / the DriverKit system
     extension if macOS prompts.

2. **Real `Ctrl+Option+H` (Rectangle's OWN shortcut, no Karabiner leader)?**
   - Snaps left → Rectangle's native real-key hotkeys are solid. The ONLY broken
     thing is the Ctrl+Space leader. (NOTE: I "tested" this earlier with a
     SYNTHETIC `hs.eventtap.keyStroke` and it didn't move — **that test is
     INVALID**; synthetic CGEvents don't exercise Rectangle's RegisterEventHotKey
     the same way real keys do, and Karabiner never sees hs synthetic events at
     all. Disregard that result. Rectangle's native keys are UNTESTED with real
     fingers.)
   - Nothing → Rectangle isn't catching real keystrokes (permissions/registration).

## STRONG RECOMMENDATION FOR THE NEXT PERSON

**Stop trying to make the bespoke Karabiner leader work by trial-and-error.** That
is the same fragile-bespoke trap the morning retrospective is about. Get EJ to a
WORKING state on a proven primitive FIRST, then add niceties:

- **Fastest reliable win:** if canary #2 passes, just use **Rectangle Pro's native
  shortcuts** (already configured: `⌃⌥H/J/K/L` halves, `⌃⌥M` max, `⌃⌥⌘O/U`
  displays). One chord, Carbon hotkeys, secure-input-immune. Costs the leader UX
  but it WORKS today. EJ called changing the chord a "last resort" — discuss.
- **If keeping the Ctrl+Space leader:** the rule logic is sound (it fired once).
  The reliable reload is **`launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.Karabiner-Core-Service-rev2`**,
  NOT `--select-profile`. Verify each edit actually applies by watching
  `/tmp/kbn-debug.log` update. Each direction key fires the URL scheme via
  `shell_command` (proven), so once the leader+variable plumbing is confirmed
  live, it should work end to end.

## CURRENT STATE OF FILES (cleanup debt)

- **`~/.config/karabiner/karabiner.json`** — window-mode rule is in **DEBUG STATE**:
  - Has `/bin/echo ... >> /tmp/kbn-debug.log` traces in every manipulator. REMOVE.
  - Auto-exit timeout was **removed** for debugging (mode stays armed until a
    direction or Ctrl+Space again). RESTORE a timeout — but make it generous
    (~2000ms, not 900ms; 900 was too short for deliberate typing and was itself a
    red herring suspect). Re-add `to_delayed_action` + `parameters`.
  - Directions fire `open 'rectangle-pro://execute-action?name=...'`. Keep.
  - Notification banner via `set_notification_message` (id `winmode`) — keep, it's
    the visual feedback the old HS HUD used to give. Its absence is a big part of
    why it *felt* dead even when the leader fired.
  - Pre-existing unrelated bug: double-right-shift maps to `/Users/ejfox/bin/mic-toggle`
    which **does not exist** (Karabiner logs `No such file or directory`). Fix or remove.
- **`~/.dotfiles/hammerspoon/init.lua`** — Hammerspoon window-mode **deleted**
  (367 → 170 lines). Hue-key lights intact. Backup of the old file at
  `/tmp/init.lua.bak` (ephemeral — copy somewhere durable if you want it).
- **Rectangle Pro** (`com.knollsoft.Hookshot`) native shortcuts still configured
  and untouched.

## DON'T REPEAT THESE MISTAKES

1. You cannot test real keystrokes yourself. `hs.eventtap.keyStroke` does NOT
   exercise Karabiner (it's above Karabiner's HID grab) and is an unreliable test
   of other apps' Carbon hotkeys. **Ask the user to press real keys, early.**
2. `--select-profile` to the active profile ≠ reload. Use `launchctl kickstart -k`
   and CONFIRM via the trace log that the new config is live before asking for a test.
3. Isolate layers (grab? Rectangle? leader?) with canaries BEFORE building. One
   measured `open URL` + two human key-taps would have scoped this in 5 minutes.

See also: `RETROSPECTIVE-window-mode.md` (same dir) and the memory
`hammerspoon-window-mode-fragile.md`.
