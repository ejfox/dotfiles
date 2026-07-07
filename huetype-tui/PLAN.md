# huetype-tui: Rust rewrite plan

Target: replace `~/.dotfiles/bin/huetype-tui` (Python, 914 LOC) with a single
static binary built from this directory. Same feature surface, instant input
response, single binary sibling to `hue-stream` (Node daemon) and `huetype`
(bash CLI).

The Python version stays functional during the port. Cut over only when the
Rust build achieves feature parity.

## Why rewrite

The Python version works but feels sluggish — not because Python is slow in
the abstract, but because the shape of the work is a poor fit:

| Cost center                       | Python reality                  | Rust reality                 |
| --------------------------------- | ------------------------------- | ---------------------------- |
| Startup                           | ~120 ms (interpreter)           | ~5 ms                        |
| Full-screen redraw per tick       | ANSI string concat + flush      | `ratatui` diff (changed cells only) |
| HTTP poll blocking                | Threads + GIL contention on render | `tokio` async, true parallel |
| Stdin input latency               | `select()` + manual escape drain | `crossterm::event` — framework-managed |
| Memory                            | ~30 MB                          | ~3–5 MB                      |

The pivotal one is redraw. Every tick, Python re-renders the whole 30-row
screen, ANSI-encodes it into a ~4 KB buffer, writes + flushes to the pty.
That's fine at 2 Hz but defeats sub-frame responsiveness. `ratatui` tracks
the previous buffer and emits only the cells that actually changed — typical
per-frame output in steady state is dozens of bytes.

## Scope

### In
- Live light grid (rooms, on/off, brightness, truecolor swatches)
- Selection cursor with ↑↓ navigation
- ←→ brightness ±10% on selected light, optimistic overlay
- `Enter` toggle on/off
- `s` sync selected light to huetype targets
- `t` toggle tap, `m` cycle mode, `c` cycle palette, `p` fzf room picker
- `SPACE` test pulse, `r` force refresh, `?` help modal, `q` quit
- Live typing stats (UDP :9998 from Hammerspoon): streak / WPM / current hue
- Daemon health indicator (pgrep)
- Palette gradient preview using HCL→sRGB

### Out (stays as-is)
- `hue-stream.js` daemon — Node.js, DTLS streaming, works well
- `huetype` bash CLI — orchestrates hs + file writes
- Hammerspoon `init.lua` tap — event-tap, file pathwatcher
- Hue Entertainment group management — happens via daemon's `ensureConfig`

### Explicit non-goals for v1
- SSE event-stream integration (optional follow-up; polling is fine for now)
- Windows / Linux support (only macOS matters here)
- Configuration file beyond the existing `~/.config/hue-key/*`
- Fancy animation / transitions in the TUI itself

## Architecture

Single binary. Async on `tokio`. All long-running work in tasks; the UI loop
only reads shared state.

```
┌─────────────────── main() #[tokio::main] ────────────────────────┐
│                                                                   │
│  ┌──────────────┐   ┌──────────────┐   ┌───────────────────┐     │
│  │ lights_task  │   │ daemon_task  │   │ stats_task        │     │
│  │ poll Hue API │   │ pgrep every  │   │ UDP bind :9998,   │     │
│  │ every 1.5s   │   │ 2s           │   │ recv stats JSON   │     │
│  └──────┬───────┘   └──────┬───────┘   └────────┬──────────┘     │
│         │                  │                     │                │
│         └──────────┬───────┴─────────────────────┘                │
│                    ▼                                              │
│              Arc<Mutex<AppState>>                                 │
│                    ▲                                              │
│         ┌──────────┴────────────┐                                │
│         │  event loop (main)    │                                │
│         │                       │                                │
│         │  tokio::select! {     │                                │
│         │   crossterm events,   │  → update AppState             │
│         │   tick interval,      │                                │
│         │  }                    │                                │
│         │  ratatui::draw()      │  → diff render                 │
│         └───────────────────────┘                                │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

State sharing: a single `Arc<Mutex<AppState>>`. Workers call `.lock()`
briefly to write; the render reads it briefly. Mutex contention is negligible
given the update rates.

Optimistic overlay for user actions lives in `AppState` as a
`HashMap<LightId, (Override, Instant)>`. Entries expire after 3s — same
pattern as the Python version.

## Dependencies

```toml
[package]
name = "huetype-tui"
version = "0.1.0"
edition = "2021"

[dependencies]
ratatui = "0.29"          # TUI framework
crossterm = "0.28"        # Terminal backend (macOS + tmux OK)
tokio = { version = "1", features = ["rt-multi-thread", "macros", "net", "time", "sync", "signal", "process"] }
reqwest = { version = "0.12", default-features = false, features = ["json", "rustls-tls"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"
dirs = "5"                # for HOME resolution
once_cell = "1"
```

**rustls over OpenSSL** — no system OpenSSL dependency, smaller binary, no
linker surprises on macOS. The Hue bridge's self-signed cert is accepted via
`ClientBuilder::danger_accept_invalid_certs(true)` (matches the Python and
Node clients' behavior — LAN-only, bridge IP is fixed).

Binary-size budget: target < 5 MB release build. Strip symbols
(`strip = "symbols"` in `[profile.release]`). No LTO initially.

## Module layout

```
huetype-tui/
├── Cargo.toml
├── PLAN.md                       # this file
├── README.md                     # short: install, run, keys
└── src/
    ├── main.rs                   # tokio runtime, event loop, select!
    ├── app.rs                    # AppState, LightState, OptimisticOverride
    ├── ui/
    │   ├── mod.rs                # draw() dispatcher
    │   ├── status.rs             # top status line
    │   ├── activity.rs           # live stats + hue swatch
    │   ├── rooms.rs              # light grid (main body)
    │   ├── footer.rs             # keybind hints + transient status
    │   └── help.rs               # modal overlay
    ├── hue/
    │   ├── mod.rs
    │   ├── client.rs             # reqwest wrapper, shared bridge client
    │   ├── types.rs              # serde structs matching /clip/v2 responses
    │   └── writes.rs             # set_light (brightness, on/off) async
    ├── workers/
    │   ├── mod.rs
    │   ├── lights.rs             # poll /resource/light every 1.5s
    │   ├── daemon.rs             # pgrep every 2s
    │   └── stats.rs              # UDP bind :9998, parse HS packets
    ├── config.rs                 # read ~/.env + ~/.config/hue-key/*
    └── color.rs                  # HCL→sRGB, xy→sRGB, mirek→sRGB, palette gradients
```

Keeping the Python version's module boundaries (render → sections, hue →
client+types+writes) makes the port mechanical and review-able.

## Build & install

```bash
cd ~/.dotfiles/huetype-tui
cargo build --release
# target/release/huetype-tui
```

Cutover plan (only after feature parity):

```bash
# Keep the Python version as a fallback
mv ~/.dotfiles/bin/huetype-tui ~/.dotfiles/bin/huetype-tui-py
ln -sf ~/.dotfiles/huetype-tui/target/release/huetype-tui ~/.dotfiles/bin/huetype-tui
# ~/bin/huetype-tui already symlinks to ~/.dotfiles/bin/huetype-tui, so done.
```

Git: commit the Rust source. `target/` stays in `.gitignore` (standard Rust
.gitignore applies).

## Step-by-step build order

Each step ships a runnable binary — the TUI grows feature by feature rather
than big-bang. This keeps feedback loops tight.

1. **Scaffold.** `cargo init`, add deps, `main()` prints "huetype-tui vX.Y.Z"
   and exits. Confirm `cargo build --release` produces a < 5 MB binary.
2. **Config loader.** Parse `~/.env`, read `~/.config/hue-key/{mode,enabled,targets,palette}`.
   `main` prints the parsed state and exits. Shakes out serde + dirs.
3. **Hue client.** `hue::Client::new(bridge, key)` with rustls + accept-invalid-certs.
   Implement `get_lights()`, `get_rooms()`, `get_entertainment()`,
   `get_entertainment_configurations()`. `main` prints light count and exits.
4. **Static render.** Basic `ratatui` screen showing "Connected: 15 lights, 6 rooms, 7 streamed".
   Confirms terminal backend works under tmux + Ghostty.
5. **Polling loop.** Spawn `lights_task`, the UI reads `Arc<Mutex<AppState>>`.
   Render the room/light grid with truecolor swatches. No input yet — `q` exits.
6. **Keyboard basics.** Crossterm event loop; `q` / `Ctrl-C` quit. Arrow keys
   log to a debug line.
7. **Selection + render cursor.** `↑↓` navigate. Stable on re-poll (keyed by
   light UUID).
8. **Brightness control.** `←→` with optimistic overlay + `hue::set_light` via
   a spawned task. Expiry after 3s.
9. **On/off toggle.** Enter key; same pattern.
10. **Sync-to-typing.** `s` — append/remove the selected light's name in
    `~/.config/hue-key/targets`. HS's pathwatcher picks it up automatically.
11. **Daemon health.** `daemon_task` (pgrep hue-stream.js). Render indicator
    in status line; disable SPACE (test pulse) when down.
12. **Mode / palette / tap cycles.** `m`, `c`, `t` — write to config files or
    shell out to `huetype`. Live reload happens via the HS pathwatcher loop.
13. **Stats listener.** Bind UDP `:9998`. Parse packets from Hammerspoon.
    Render the activity line (hue swatch, streak, WPM).
14. **Test pulse.** `SPACE` — send UDP `pulse` message to `:9999` with the
    active targets.
15. **Pick (fzf).** `p` — `Command::new("huetype").arg("pick")`. Needs to
    release the terminal raw mode while fzf runs, then re-acquire. Crossterm
    has `disable_raw_mode` / `enable_raw_mode` for exactly this.
16. **Help modal.** `?` — overlay with keybind table + config paths + daemon
    status. Any key dismisses.
17. **Polish.** Palette gradient in status line (8-swatch HCL traversal).
    Activity line swatch matches current hue. Room sort: streamed first,
    alphabetical within group. Narrow-terminal graceful degrade.
18. **Cutover.** See "Build & install" above.

Milestones where I'd expect to stop and compare side-by-side against the
Python version: steps 5, 9, 13, 17.

## Key design decisions (with rationale)

**Why `tokio::select!` over a polling loop?**
Crossterm has `event::poll(Duration)` which blocks a thread. The event loop
must also react to tick-interval (e.g. clock updates) and worker messages.
`select!` across three async sources is cleaner than juggling threads and
channels — and the whole program is already async because `reqwest` is.

**Why `Arc<Mutex<...>>` instead of channels?**
Workers push snapshots (not streams of events) — the UI only ever needs the
latest. A lock-guarded dict is simpler than a `broadcast` channel. Lock
held only long enough to clone a small `LightState` vec; no contention worth
worrying about.

**Why keep Python around during the port?**
Rewrites fail when they break the working thing. The Rust binary installs
under a different name until it reaches parity.

**Why accept-invalid-certs?**
The Hue bridge uses a self-signed cert bound to its IP. Pinning the public
key is future work; for a local-network app matching the Node daemon's
behavior is fine.

**Why not `textual` (Python) instead?**
Would fix the redraw model but keeps interpreter startup, GIL, and a heavier
runtime than a static Rust binary. Also adds a pip install step to the
setup. If the answer is "use a real TUI framework" anyway, `ratatui` is the
stronger choice and gives us a single binary.

## Risks & unknowns

- **Crossterm under tmux + Ghostty**: well-supported, but key-repeat rate
  and escape-sequence handling can surprise. Mitigation: step 6 is
  explicitly a key-input shakeout before committing to the full redesign.
- **Binary size**: default `reqwest` + `tokio` + `ratatui` is ~4 MB stripped.
  Acceptable. If we cared, could swap to `ureq` (blocking HTTP, no
  reqwest/tokio/hyper stack) at the cost of simpler but less composable
  workers. Not worth it yet.
- **Hue API schema drift**: we're pinning against the current `/clip/v2`
  shapes. If Philips changes things, both Python and Rust break together.
  Cost is identical.
- **tmux scrollback pollution**: alternate-screen mode (crossterm
  `EnterAlternateScreen`) avoids leaving frames in the scrollback on exit.
  Same pattern as `vim`, `less`.
- **Graceful shutdown**: crossterm's raw mode must be disabled even on panic.
  Use a RAII guard (`struct TermGuard` with `Drop`) to always restore the
  terminal, so a panicking render doesn't leave a wrecked pty.

## Success criteria

- Input latency (keypress to visible reaction): < 50 ms at p99. Measure with
  a one-line timing harness in debug builds.
- Startup time (`huetype-tui` to first frame): < 100 ms.
- RSS in steady state: < 10 MB.
- Feature parity with Python `v0.4.0`.
- Runs for a full workday without crashes or leaks (memory flat over 8 h).
- Single binary, no runtime deps.

## Open questions for EJ (parked)

These don't block the port but are worth a decision during or after:

- Should the TUI gain an SSE event-stream subscription so light state
  updates are instant (vs 1.5s polling)? The answer doesn't change the
  architecture — it's an additional task in the `workers/` tree.
- Should the Rust crate also pull in a `huetype` CLI subcommand layer so the
  bash script can eventually retire? Would unify the surface but adds
  scope. Default: no for v1.
- Color-temp-aware baseline for subtle mode — currently hardcoded warm white.
  Could read a scene's color temp from the Hue API and use that. Nice to
  have, not blocking.
