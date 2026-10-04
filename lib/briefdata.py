"""briefdata — the morning brief's facts, for pixel scenes.

The VPS brief writes /home/debian/briefs/facts.json (every 30 min, plus each
brief slot); things-bridge pulls it to ~/.local/state/pixel/brief.json. Scenes
only ever read that local file, so they never touch the network at draw time.
Things data comes straight from the local things-bridge export.

    from briefdata import brief, things, age_min
    b = brief()            # {} when missing/unreadable
    b.get("ips", [])
"""
import json
import os
import time
from datetime import datetime, timezone

BRIEF = os.path.expanduser("~/.local/state/pixel/brief.json")
THINGS = os.path.expanduser("~/.local/share/things-bridge/things.json")


def _load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return {}


def brief():
    return _load(BRIEF)


def things():
    return _load(THINGS)


def age_min(d, key="generated_at"):
    """Minutes since an ISO8601 timestamp in d[key]; None if unknown."""
    ts = (d or {}).get(key)
    if not ts:
        return None
    try:
        t = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        return (datetime.now(timezone.utc) - t).total_seconds() / 60
    except Exception:
        return None


def stamp(d, key="generated_at"):
    """Short freshness label for a scene footer: 'facts 12m', 'facts 3h'."""
    m = age_min(d, key)
    if m is None:
        return "facts ?"
    return f"facts {int(m)}m" if m < 90 else f"facts {int(m // 60)}h"


def ring(cx, cy, r, rgb, step_deg=6, s=1):
    """Dotted circle as /batch dots (the device's /circle is filled)."""
    import math
    dots = []
    for a in range(0, 360, step_deg):
        x = int(cx + r * math.cos(math.radians(a)))
        y = int(cy + r * math.sin(math.radians(a)))
        if 0 <= x < 320 and 0 <= y < 240:
            dots.append({"x": x, "y": y, "s": s, "r": rgb[0], "g": rgb[1], "b": rgb[2]})
    return dots


def chunks(dots, n=80):
    """/batch parser is loose; keep requests around 80 dots."""
    for i in range(0, len(dots), n):
        yield dots[i:i + n]
