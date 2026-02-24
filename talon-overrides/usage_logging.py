"""Log all Talon voice commands to JSONL for usage analysis.

Matches the format used by shell and tmux usage logging:
  ~/.local/share/usage-logs/talon/YYYY-MM-DD.jsonl

Each line: {"ts":"...","src":"talon","evt":"phrase","text":"mux zoom","words":2,"app":"Ghostty"}
"""

import json
import os
from datetime import datetime
from pathlib import Path

from talon import app, ui

LOG_DIR = Path.home() / ".local" / "share" / "usage-logs" / "talon"


def log_phrase(d):
    text = d.get("text")
    if not text:
        return

    phrase = " ".join(text)
    if not phrase.strip():
        return

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = LOG_DIR / f"{datetime.now():%Y-%m-%d}.jsonl"

    try:
        active_app = ui.active_app().name
    except Exception:
        active_app = "unknown"

    entry = {
        "ts": datetime.now().isoformat(),
        "src": "talon",
        "evt": "phrase",
        "text": phrase,
        "words": len(text),
        "app": active_app,
    }

    try:
        with open(log_file, "a") as f:
            f.write(json.dumps(entry) + "\n")
    except Exception:
        pass  # never break Talon over logging


def on_ready():
    from talon import speech_system
    speech_system.register("phrase", log_phrase)


app.register("ready", on_ready)
