# Window Mode — ⌥Space (Option+Space) → Rectangle Pro

> ## ✅ RESOLVED 2026-06-29 — and the ENTIRE prior diagnosis was barking up the wrong tree
> The leader is **⌥Space** (Option+Space), NOT Ctrl+Space. Press ⌥Space, then a direction.
> - **Directions:** `h`←  `l`→  `k`↑  `j`↓ **and the arrow keys** ←→↑↓ ; `space` = maximize ; `esc`/`q`/2s = exit.
>
> ### 🚨 BROKEN AGAIN? DO THIS FIRST — open **Karabiner-EventViewer**, press your leader, READ what it emits.
> That one step would have saved ~2 hours. Do NOT touch daemons, drivers, permissions, or reboot until you have
> confirmed *what key codes the keyboard actually sends.* Then `cat /tmp/kbn-debug.log` to see which rule fired.
>
> **The 5 real bugs (none were daemon/driver/permission/reboot — all of those were green the whole time):**
> 1. **Modifier mismatch (the big one).** The Ergodox EZ thumb key sends **`left_option`**, but the rule required **`control`** → rule never matched, log stayed empty. EventViewer showed `flags left_option` in 5 seconds. Fix: leader fires on `option` (kept `control` too).
> 2. **Directions only matched bare keys.** You hold Option while tapping the direction, so `h` arrived as `option+h` and didn't match a bare-`h` manipulator. Fix: `from.modifiers.optional: ["any"]` on every direction/exit.
> 3. **`space` was overloaded.** Leader = ⌥**Space** AND maximize = **Space**; the "re-press leader to cancel" manipulator stole Space from maximize. Fix: **deleted the toggle-off manipulator** (esc/q/2s already exit).
> 4. **`to_if_canceled` race.** Pressing a direction fired the leader's `to_if_canceled` (winmode→0) *before* the direction manipulator evaluated `winmode==1`, so it cancelled instead of snapping. Fix: **removed `to_if_canceled`**; directions self-disarm and the 2s `to_if_invoked` timeout backstops.
> 5. **Arrow keys were never bound** (only h/j/k/l existed). Fix: added ←→↑↓ mirroring h/l/k/j.
>
> **Lesson:** when a Karabiner rule "does nothing," the first move is **EventViewer** (what is emitted?) + `/tmp/kbn-debug.log` (what fired?). Config/driver/daemon/permission checks are last, not first. `window-mode-doctor` still works for the machine-side green-light pass, but it can't see a modifier mismatch — only EventViewer can.

<details><summary>Old (pre-2026-06-29) triage banner — kept for history, but the above supersedes it</summary>

> ```
> window-mode-doctor
> ```
> 30-second triage: Ctrl+Space then `h` snaps? done. Nothing/Cmd-Tab sticky? reboot. Still dead? old *Next actions*.
> The "NEVER thrash daemons" warning still holds — but note the actual 2026-06-29 root cause was a **modifier mismatch**, not the runtime.
</details>

_Authoritative doc. Last updated **2026-06-29** (root cause finally found: Option-vs-Control + 4 follow-on rule bugs)._
_Supersedes `~/.dotfiles/hammerspoon/HANDOFF-window-mode-2026-06-27.md` and `RETROSPECTIVE-window-mode.md` — **read this first.**_

---

## TL;DR — where this actually stands

- **The feature:** `Ctrl+Space` (Karabiner leader) → `h/j/k/l` snap window halves, `space` = fill/maximize, via Rectangle Pro. **One-shot:** each snap exits the mode immediately; `esc`/`q` or 2 s of idle also exit. It **cannot get stuck** — unlike the old debug-state version that ate your spacebar for 54 seconds.
- **The config is GOOD — and the design is now *audit-verified correct.*** Valid JSON, passes Karabiner's linter, fired correctly at 10:46 on 2026-06-27, and the one-shot rule matches the *canonical* Karabiner temporary-layer pattern from the official docs.
- **What broke is the RUNTIME, not the config or the driver.** A long debugging session restarted Karabiner's daemons repeatedly (`launchctl kickstart`/`kill`) — including mid-keypress — which **dropped key-up events → stuck modifier keys** (Cmd-Tab sticking; a stuck Ctrl/Cmd also keeps `Ctrl+Space` from reading cleanly). `simple_modifications` (Caps→Esc) kept working throughout. The DriverKit driver stayed `[activated enabled]` the whole time — never broken.
- **THE FIX: a reboot** is the sure way to clear a stuck modifier — but it's probably **already self-healed** (a stuck modifier lives in macOS input state and clears with normal typing), so **test as-is first.**

---

## ✅ Audit verdict (2026-06-27, web-verified)

A follow-up audit (Karabiner's own logs + official docs + GitHub issues) re-checked every claim. The diagnosis mostly holds — with two corrections worth having.

**Confirmed:**
- **Config is correct.** The one-shot rule (`set_variable` in `to`, reset in *both* `to_if_invoked` and `to_if_canceled`, layer keys gated on `variable_if`) is the canonical Karabiner temporary-layer pattern; `basic.to_delayed_action_delay_milliseconds` is the right delay param (default 500 ms); `to_if_canceled` fires immediately on the next key.
- **Driver is fine.** `driver_version is mismatched` was **never** logged, and the DriverKit extension is `[activated enabled]`. The `16.0.0 / 6.14.0 / 1.8.0` version split (app / VirtualHIDDevice-Daemon / dext) is independent component versioning — *not* a mismatch.
- **`invalid shared secret` is benign** — it appears only during the sub-second IPC handshake at each restart and immediately resolves to `verified peer connected`. (78 of them only because the session restarted that many times.)
- **Stuck modifiers are a documented Karabiner issue** caused by *"physical keyboard events missed during capture"* — a key-up dropped while the grabber restarts. The repeated mid-keypress restarts caused exactly that.

**Corrected (I had these wrong):**
- ⚠️ **"Never kickstart Karabiner daemons" was overstated.** The *official* CLI restart **is** a kickstart — of exactly one service: `launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server`. The damage came from restarting the *other* services (`Karabiner-Core-Service-rev2`, `NotificationWindow`) repeatedly and in mixed order, mid-keypress. **Use the official one-liner; leave the others alone.**
- ⚠️ **A reboot may be unnecessary.** A stuck modifier isn't Karabiner state — it clears by re-pressing the modifier, and after hours of use is likely already gone. Test before rebooting.

Sources: [Restart doc](https://karabiner-elements.pqrs.org/docs/manual/operation/restart/) · [to_delayed_action doc](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to-delayed-action/) · [#3603 driver mismatch](https://github.com/pqrs-org/Karabiner-Elements/issues/3603) · [#774 stuck shift](https://github.com/pqrs-org/Karabiner-Elements/issues/774)

---

## ⭐ Next actions — do these in order

1. **Test as-is first** — it's likely self-healed. Do step 4. If `Ctrl+Space` works, skip ahead. **If Cmd-Tab still sticks or keys feel flaky → reboot** (sure fix for a stuck modifier), then continue. Driver + config are fine; this is only a possibly-stuck modifier.
2. **Canary 1 — is the grab attached?** Tap **Caps Lock**. The caps LED should **NOT** light (Karabiner remaps it to Escape).
   - LED stays off → grab alive. ✅ continue.
   - LED lights up → grab not attached → reboot, then re-check.
3. **Canary 2 — do complex_modifications fire?** In a text field, **double-tap Left Shift fast** → should **Select-All** (⌃A).
   - Selects all → complex mods are live. ✅ continue.
   - Nothing → check Karabiner-Elements GUI shows the rules enabled.
4. **The feature.** Click a normal window (Finder/browser), press **`Ctrl+Space` then `h`**, then immediately **type some spaces**.
   - Expect: window snaps left, spaces type normally.
   - Confirm independently: `cat /tmp/kbn-debug.log` → should show `LEADER-on` then `DIR-h-fired`, and **no** runaway `DIR-space`.
5. **If it all works → do the cleanup** (see *Remaining cleanup debt*).
6. **If Canary 2 passes but `Ctrl+Space` specifically won't fire** → it's a Ctrl+Space conflict, not a Karabiner failure → see *Ctrl+Space-specific notes*.

---

## Architecture — and why it's shaped this way

Two layers, both chosen because they sit **below** the macOS Secure Event Input / `CGEventTap` layer that silently killed the original Hammerspoon implementation:

```
key press
   │
   ▼
Karabiner-Elements (DriverKit virtual HID — kernel level, secure-input-immune)
   │   complex_modification "Window mode":
   │     Ctrl+Space  → set var winmode=1, show HUD notification, arm 2s timeout
   │     h/j/k/l/spc → (while winmode==1) fire Rectangle URL + set winmode=0  ← one-shot
   │     esc/q       → (while winmode==1) set winmode=0
   ▼
/usr/bin/open 'rectangle-pro://execute-action?name=left-half'   (URL scheme, not a hotkey)
   │
   ▼
Rectangle Pro (Carbon window-server registry — also secure-input-immune)  → moves the window
```

**Why not pure Hammerspoon?** The original modal was an `hs.eventtap` (a raw `CGEventTap`). macOS **Secure Event Input** (any focused password field — Safari login, autofill, even a backgrounded tab) silently starves a `CGEventTap`: zero key events delivered, while `isEnabled()` still reports `true`. Total, invisible deafness. Divvy/Rectangle "just work" because they use `RegisterEventHotKey` (Carbon), which secure input does **not** starve. Karabiner's DriverKit HID is below it too. So this hybrid keeps the leader UX while making the two load-bearing parts immune.

**Why the URL scheme and not Rectangle's own hotkeys?** Rectangle Pro has no leader/prefix-key feature, so Karabiner provides the leader and triggers Rectangle by URL (`rectangle-pro://execute-action?name=…`), which bypasses hotkeys entirely. Rectangle's native shortcuts still exist as a fallback (see below).

---

## What is TRUE right now (measured this session — with the command to re-verify each)

| Fact | Re-verify |
|---|---|
| Karabiner-Elements **16.0.0**, all agents run | `launchctl list \| grep -i karabiner` |
| DriverKit extension **`[activated enabled]`** (driver layer healthy) | `systemextensionsctl list \| grep -i pqrs` |
| **No** `driver_version is mismatched` ever logged | `grep -i 'driver_version\|mismatch' ~/.local/share/karabiner/log/*.log` |
| Config is **valid JSON** | `python3 -m json.tool ~/.config/karabiner/karabiner.json` |
| Window rule passes **Karabiner's linter** | extract rule → `karabiner_cli --lint-complex-modifications <file>` (see *Commands*) |
| Window rule **fired correctly at 10:46** (one-shot pre-thrash) | trace below |
| **Caps→Esc** simple mod works = grab can attach | tap Caps, LED stays off |
| **Rectangle Pro** running, URL scheme proven by frame-measurement | `pgrep -fl 'Rectangle Pro'` |
| Rectangle bundle = `com.knollsoft.Hookshot` | `defaults read com.knollsoft.Hookshot \| grep -iE 'half\|maximize'` |

**Trace proof it works** (`/tmp/kbn-debug.log`, 2026-06-27 10:46, before the daemon thrashing):
```
10:46:01 LEADER-on        ← Ctrl+Space armed
10:46:01 DIR-k-fired      ← k snapped top-half (Rectangle moved the window)
10:46:03 LEADER-off       ← Ctrl+Space disarmed
```
The only reason it then *looked* broken: the old config had **no timeout and no esc handler**, so it stayed armed and ate the spacebar. That's fixed in the current one-shot rule.

---

## What went wrong this session (root cause, so nobody repeats it)

1. The old config's window-mode had its auto-exit timeout deleted (debug state) and never had an `esc` handler → it got **stuck armed**, eating spaces. (Real bug — fixed by the one-shot rewrite.)
2. Chasing a stale fear ("edits aren't reaching Karabiner") from the old handoff, the session **restarted Karabiner daemons repeatedly** (`launchctl kickstart`/`kill`) — and crucially restarted the *wrong* services (`Karabiner-Core-Service-rev2`, `NotificationWindow`) in mixed order, some of it mid-keypress.
3. That left the user-space agents in **mixed/half-synced states** and **dropped key-up events → stuck modifier keys** (Cmd-Tab sticking; a stuck Ctrl/Cmd also makes `Ctrl+Space` not read cleanly). The DriverKit driver stayed `[activated enabled]` throughout — never the problem.
4. The config was never the problem after the rewrite (it lints clean and matches the canonical pattern). **The runtime was destabilized by the daemon thrashing; the only lasting symptom is a stuck modifier, which a reboot or a modifier re-press clears.**

**Lesson in one line:** *To reload, just save `karabiner.json`. To restart, use the official single `console_user_server` kickstart. Never thrash the other Karabiner services — especially mid-keypress — or you drop key-ups and stick modifiers.*

---

## Operating method — how to debug this WITHOUT flailing

These are the laws that, if followed from minute 1, make this a 10-minute job:

1. **Measure before you mutate; confirm after.** Read state before any edit. After any edit/reload, require an *observable* signal it landed (a `/tmp/kbn-debug.log` line, a log entry) before believing it.
2. **Isolate layers before composing them.** The stack = `[HID grab] → [rule loaded] → [rule matches the key] → [Rectangle executes]`. Test each with a test that *can fail* (the canaries) before testing end-to-end.
3. **Only valid evidence counts.** Synthetic keystrokes (`hs.eventtap.keyStroke`, `osascript key code`) do **not** exercise Karabiner's HID grab or Rectangle's Carbon hotkeys — discard such results. Real fingers only for the grab.
4. **The human's fingers are the scarcest resource — batch them.** Exhaust machine-observable state first, then hand over ONE test sheet with an if→then decision tree. Never guess-and-check live.
5. **Working baseline first, niceties second.** Get a confirmed snap, commit it, *then* restore polish.
6. **No debug debt.** Track every trace / removed timeout / dead path and clean it before "done."

---

## DON'T (each of these cost real time this session)

- ⚠️ **Reload vs restart vs reboot — know the difference:**
  - **Reload config:** just save `karabiner.json` — Karabiner watches it and auto-reloads. (Confirm via the trace, not faith.)
  - **Restart Karabiner:** the *official* one-liner ONLY — `launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server`. Or the GUI (menu bar / Settings).
  - **Reboot:** only when a modifier is genuinely stuck and re-pressing it doesn't clear it.
- ❌ **Do NOT kickstart/kill the *other* Karabiner services** (`Karabiner-Core-Service-rev2`, `NotificationWindow`, etc.) to "reload" — repeatedly, in mixed order, or mid-keypress. That desyncs the stack and drops key-ups → **stuck modifiers**. This single mistake caused most of the original session's pain.
- ❌ **Don't trust `karabiner_cli --select-profile 'X'`** as a reload — it's a **no-op when X is already selected** (there's only one profile here).
- ❌ **Don't test with synthetic keystrokes.** They bypass Karabiner entirely and don't exercise Rectangle's Carbon hotkeys. Invalid evidence.
- ❌ **Don't believe a stuck HUD banner = stuck mode.** Forcing `winmode=0` via CLI frees the keys but does **not** dismiss the on-screen notification (only a manipulator or a fresh process clears it). A ghost banner ≠ a functional trap.

---

## Key locations & commands

```bash
# Live config (standalone, NOT symlinked):
~/.config/karabiner/karabiner.json
# Dotfiles copies — NOTE: ~/.dotfiles/.config/karabiner/ is SYMLINKED to the live dir
# (editing the live file updates it automatically). Only ~/dotfiles (no dot) is a separate copy.

# Safety backup from this session:
~/.config/karabiner/karabiner.json.pre-winmode-fix-2026-06-27

# Trace log (debug echoes in the rule write here):
/tmp/kbn-debug.log
KC="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

# --- Read-only ground truth (run ALL of this before touching anything) ---
launchctl list | grep -i karabiner                       # agents + last exit codes
ps aux | grep -i karabiner | grep -v grep                # processes (note start times)
systemextensionsctl list | grep -i pqrs                  # is the dext [activated enabled]?
python3 -m json.tool ~/.config/karabiner/karabiner.json  # JSON valid?
grep -i 'driver_version\|mismatch' ~/.local/share/karabiner/log/*.log   # driver health
tail -20 ~/.local/share/karabiner/log/console_user_server.log           # connection state
cat /tmp/kbn-debug.log 2>/dev/null                       # did the rule fire?
pgrep -fl 'Rectangle Pro'                                # snap target alive?

# --- Lint just the window rule with Karabiner's own validator ---
python3 -c "import json;d=json.load(open('$HOME/.config/karabiner/karabiner.json'));print(json.dumps({'rules':[d['profiles'][0]['complex_modifications']['rules'][0]]}))" > /tmp/winrule.json
"$KC" --lint-complex-modifications /tmp/winrule.json     # prints 'ok' if valid

# --- The ONLY restart you should use (official) ---
launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server

# --- Force winmode off (rescue if it ever sticks; does NOT clear the HUD banner) ---
"$KC" --set-variables '{"winmode":0}'

# --- Rectangle URL scheme (the actual snap mechanism — test directly) ---
open 'rectangle-pro://execute-action?name=left-half'     # also right-half/top-half/bottom-half/maximize
```

**Rectangle Pro native shortcuts** (the fallback if the leader is ever abandoned): `⌃⌥H/L` = left/right half, `⌃⌥K/J` = top/bottom half, `⌃⌥M` = maximize, `⌃⌥⌘O/U` = next/prev display.

---

## The config design (one-shot rule semantics) — audit-confirmed correct

The window-mode rule is `profiles[0].complex_modifications.rules[0]`, manipulators in order:

1. **Leader-OFF** — `winmode==1` + `Ctrl+Space` → `winmode=0`, clear HUD. (Ctrl+Space toggles off.)
2. **Leader-ON** — `winmode!=1` + `Ctrl+Space` → `winmode=1`, show HUD, **`parameters.basic.to_delayed_action_delay_milliseconds: 2000`** + `to_delayed_action` where **both** `to_if_invoked` (2 s idle) **and** `to_if_canceled` (any next key) set `winmode=0`. → the hard safety backstop; the mode literally cannot outlive one keypress or 2 seconds.
3. **Directions** — `winmode==1` + `h/l/k/j/spacebar` → set `winmode=0` (one-shot) + clear HUD + `open rectangle-pro://…`.
4. **Exits** — `winmode==1` + `escape`/`q` → `winmode=0` + clear HUD (consumes the key, silent exit).

This is the **canonical Karabiner temporary-layer pattern** (per the official `to_delayed_action` docs: set a variable in `to`, reset it in both `to_if_invoked`/`to_if_canceled`, gate the layer keys on `variable_if`). `to_if_canceled` firing immediately on the next key is what makes it reliably one-shot.

Why one-shot (chosen 2026-06-27 over timed-chaining): the 54-second trap that started this becomes *structurally impossible*. To do N snaps you re-press Ctrl+Space N times (Divvy muscle memory). To switch to timed/chaining instead, give the directions a `to_delayed_action` that re-arms rather than self-disarming.

---

## Ctrl+Space-specific notes

`Ctrl+Space` is the macOS default for **"Select the previous input source."** Karabiner (when the grab is healthy) sees it first and the rule swallows it. **If, on a clean/rebooted system, Canary 2 passes (complex mods fire) but `Ctrl+Space` specifically does nothing**, suspect that conflict:
- Disable it: System Settings → Keyboard → Keyboard Shortcuts → Input Sources → uncheck "Select the previous input source."
- Or change the leader chord in the rule (e.g. `⌃;` or a `right_command` tap) and update your muscle memory.
- The rule's `from` is `spacebar` + `mandatory: ["control"]`; it fired fine at 10:46, so the chord itself is correct — this is purely about who else wants ⌃Space (or a stuck Ctrl from the daemon thrashing — which a reboot clears).

---

## Remaining cleanup debt (do after the feature is confirmed working)

- [ ] **Strip the debug traces** — every manipulator has `/bin/echo "$(date …) … " >> /tmp/kbn-debug.log`. Remove once verified (they're harmless but noisy). Keep them through verification.
- [ ] **Sync the legacy dotfiles copy** — `~/.dotfiles/.config/karabiner/` is symlinked to live (auto-synced), but `~/dotfiles/.config/karabiner/` (no dot) is separate — copy + commit (unsigned, per dotfiles rule).
- [ ] **Dead `mic-toggle`** — rule 3 (double-tap right shift) runs `/Users/ejfox/bin/mic-toggle`, which **does not exist** (errors in the log on every double-right-shift). Either create the script or remove that rule. The description string already carries a NOTE flagging it.
- [ ] **Remove the debug-instrumentation note** from the rule description once traces are gone.
- [ ] **Retire** the old `HANDOFF-window-mode-2026-06-27.md` / `RETROSPECTIVE-window-mode.md` (or leave the SUPERSEDED pointer).
