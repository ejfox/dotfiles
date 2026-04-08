from talon import actions, app, fs, scope
import os
import subprocess

SIGNAL_FILE = "/tmp/talon-mic-toggle"

# Create signal file if it doesn't exist
if not os.path.exists(SIGNAL_FILE):
    open(SIGNAL_FILE, "w").close()


def get_mic_volume():
    """Check actual macOS input volume to determine if mic is muted."""
    try:
        result = subprocess.run(
            ["/usr/bin/osascript", "-e", "input volume of (get volume settings)"],
            capture_output=True, text=True, timeout=2
        )
        return int(result.stdout.strip())
    except Exception:
        return -1


def on_signal(path, flags):
    if path != SIGNAL_FILE:
        return
    vol = get_mic_volume()
    if vol < 0:
        return
    # Sync Talon state to actual mic state: mic on = speech on, mic off = speech off
    if vol > 0:
        actions.speech.enable()
    else:
        actions.speech.disable()


fs.watch(os.path.dirname(SIGNAL_FILE), on_signal)
