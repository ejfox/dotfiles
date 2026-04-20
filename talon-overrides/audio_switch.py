"""
Auto-switch Talon mic to AirPods when available, MacBook mic when not.
Checks every 10 seconds for audio device changes.
Requires SwitchAudioSource: brew install switchaudio-osx
"""

from talon import cron, app
import subprocess
import logging

logger = logging.getLogger(__name__)

AIRPODS_NAME = "EJ's AirPods Pro"
BUILTIN_INPUT = "MacBook Pro Microphone"
BUILTIN_OUTPUT = "MacBook Pro Speakers"

_current_device = None


def _run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        return r.stdout.strip()
    except Exception:
        return ""


def _available_devices():
    out = _run(["SwitchAudioSource", "-a", "-t", "input"])
    return out.split("\n") if out else []


def check_audio():
    global _current_device
    devices = _available_devices()
    airpods_available = any(AIRPODS_NAME in d for d in devices)

    if airpods_available and _current_device != AIRPODS_NAME:
        _run(["SwitchAudioSource", "-s", AIRPODS_NAME, "-t", "input"])
        _run(["SwitchAudioSource", "-s", AIRPODS_NAME, "-t", "output"])
        _current_device = AIRPODS_NAME
        logger.info(f"Audio switched to {AIRPODS_NAME}")
    elif not airpods_available and _current_device != BUILTIN_INPUT:
        _run(["SwitchAudioSource", "-s", BUILTIN_INPUT, "-t", "input"])
        _run(["SwitchAudioSource", "-s", BUILTIN_OUTPUT, "-t", "output"])
        _current_device = BUILTIN_INPUT
        logger.info("Audio switched to MacBook built-in")


cron.interval("10s", check_audio)
app.register("ready", check_audio)
