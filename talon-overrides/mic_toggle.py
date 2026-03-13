from talon import actions, app, fs, scope
import os

SIGNAL_FILE = "/tmp/talon-mic-toggle"

# Create signal file if it doesn't exist
if not os.path.exists(SIGNAL_FILE):
    open(SIGNAL_FILE, "w").close()


def on_signal(path, flags):
    if path != SIGNAL_FILE:
        return
    modes = scope.get("mode")
    if "sleep" in modes:
        actions.speech.enable()
    else:
        actions.speech.disable()


fs.watch(os.path.dirname(SIGNAL_FILE), on_signal)
