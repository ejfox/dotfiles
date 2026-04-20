"""Push Talon mode/scope changes to sketchybar via --trigger events.

Fires on every context update (the same hook that repaints `mode_line.py`).
Non-blocking subprocess — never stalls Talon's speech loop.
"""

import subprocess
from talon import app, registry, scope

SKETCHYBAR = "/opt/homebrew/bin/sketchybar"
EVENT = "talon_state"

last_mode = None


def current_mode() -> str:
    """Map Talon's active modes to a single label matching mode_line.py."""
    modes = scope.get("mode") or set()
    if "sleep" in modes:
        return "sleep"
    if "dictation" in modes and "command" in modes:
        return "mixed"
    if "dictation" in modes:
        return "dictation"
    if "command" in modes:
        return "command"
    return "other"


def push(mode: str) -> None:
    # Fire and forget. start_new_session detaches the child so a slow sketchybar
    # never blocks Talon; stdout/stderr → DEVNULL silences ResourceWarning noise.
    subprocess.Popen(
        [SKETCHYBAR, "--trigger", EVENT, f"MODE={mode}"],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def on_update_contexts() -> None:
    global last_mode
    mode = current_mode()
    if mode != last_mode:
        last_mode = mode
        push(mode)


def on_ready() -> None:
    registry.register("update_contexts", on_update_contexts)
    # Emit current state once at startup so sketchybar isn't stuck on stale data.
    on_update_contexts()


app.register("ready", on_ready)
