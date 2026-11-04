from talon import actions, app, fs, scope
import os
import subprocess

# Own dir, NOT /tmp itself: fs.watch() on /tmp makes Talon's rescan choke on
# root-only /tmp/tmp-mount-* dirs, which silently breaks hot-reload of user files.
SIGNAL_DIR = "/tmp/talon-mic"
SIGNAL_FILE = os.path.join(SIGNAL_DIR, "toggle")

os.makedirs(SIGNAL_DIR, exist_ok=True)
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


# Speech state captured when the mic was muted, so an unmute (e.g. claude-say
# finishing) restores that state instead of blindly waking a sleeping Talon.
_speech_was_enabled = None


def on_signal(path, flags):
    global _speech_was_enabled
    if path != SIGNAL_FILE:
        return
    vol = get_mic_volume()
    if vol < 0:
        return
    if vol > 0:
        # Unmute: only wake if Talon was awake before the mute.
        if _speech_was_enabled is not False:
            actions.speech.enable()
        _speech_was_enabled = None
    else:
        # Mute: remember whether Talon was awake, then sleep it.
        if _speech_was_enabled is None:
            _speech_was_enabled = actions.speech.enabled()
        actions.speech.disable()


fs.watch(SIGNAL_DIR, on_signal)
