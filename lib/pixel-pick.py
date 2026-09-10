#!/usr/bin/env python3
"""pixel-pick — choose the next scene to show, weighted by the moment instead
of pure random. Prints one scene name (basename) to stdout.

Signals (all cheap + non-launching):
  - time of day        morning favors email/todos/weather/greeting; workday
                       favors fleet/commits/wpm; evening reading/film/music;
                       late night the ambient/quiet ones
  - robots -t          an agent that NEEDS YOU hard-boosts the fleet scene
  - email cache        emails sent today boosts the email scene (celebrate the
                       grind) while it's still that day
  - Spotify running    boosts now-playing (process check only; never launches)
  - .favorites         bonus weight, one line per scene (existing mechanism)
  - last scene         the immediately-previous scene is suppressed, so it
                       never shows the same thing twice in a row

Weighted-random over the result. Falls back to uniform if signals fail.
"""
import json
import os
import subprocess
import sys
import time

SCENES_DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
    "~/.dotfiles/bin/pixel-scenes")
HOME = os.path.expanduser("~")
LAST_FILE = "/tmp/pixel-last-scene"

# Deterministic-enough jitter without Math.random: mix time + pid.
_seed = (int(time.time() * 1000) ^ os.getpid()) & 0x7FFFFFFF


def rnd():
    global _seed
    _seed = (1103515245 * _seed + 12345) & 0x7FFFFFFF
    return _seed / 0x7FFFFFFF


def sh(cmd, timeout=3):
    try:
        return subprocess.run(cmd, capture_output=True, text=True,
                              timeout=timeout).stdout.strip()
    except Exception:
        return ""


def scenes():
    out = []
    try:
        for f in os.listdir(SCENES_DIR):
            p = os.path.join(SCENES_DIR, f)
            if not f.startswith(".") and os.path.isfile(p) and os.access(p, os.X_OK):
                out.append(f)
    except OSError:
        pass
    return out


def time_affinity(hour):
    """scene -> extra tickets by time of day."""
    if 5 <= hour < 11:      # morning
        return {"greeting": 3, "email": 3, "todos": 3, "weather": 2, "commits": 1}
    if 11 <= hour < 17:     # workday
        return {"fleet": 2, "commits": 2, "wpm": 2, "rescuetime": 2, "email": 1}
    if 17 <= hour < 22:     # evening
        return {"reading": 3, "last-film": 2, "now-playing": 2, "said": 2, "bloom": 1}
    return {"cipher": 2, "constellation": 2, "ambient-dots": 2,  # late night
            "foundation": 1, "clock": 1}


def main():
    pool = scenes()
    if not pool:
        return
    hour = time.localtime().tm_hour
    weights = {s: 1.0 for s in pool}  # base ticket each

    # time of day
    for s, boost in time_affinity(hour).items():
        if s in weights:
            weights[s] += boost

    # an agent needs you -> pull up the fleet
    counts = sh([os.path.join(HOME, ".dotfiles/bin/robots"), "-t"])
    if "◇" in counts and "fleet" in weights:
        try:
            needs = int(counts.split("◇")[1].split()[0].lstrip("◆●"))
        except Exception:
            needs = 1
        if needs > 0:
            weights["fleet"] += 8  # loud signal, wins most of the time

    # emails sent today -> celebrate the grind (only while it's still today)
    try:
        with open(os.path.join(HOME, ".local/state/pixel/email.json")) as f:
            d = json.load(f)
        if d.get("date") == time.strftime("%Y-%m-%d") and int(d.get("count", 0)) > 0 \
                and "email" in weights:
            weights["email"] += 3
    except Exception:
        pass

    # music playing -> now-playing (process check only, never launches an app)
    if "now-playing" in weights:
        procs = sh(["pgrep", "-x", "Spotify"]) or sh(["pgrep", "-x", "Music"])
        if procs:
            weights["now-playing"] += 3

    # .favorites bonus tickets (existing mechanism)
    fav = os.path.join(SCENES_DIR, ".favorites")
    if os.path.exists(fav):
        try:
            for line in open(fav):
                line = line.strip()
                if line and not line.startswith("#") and line in weights:
                    weights[line] += 1.5
        except OSError:
            pass

    # never repeat the immediately-previous scene
    try:
        last = open(LAST_FILE).read().strip()
        if last in weights and len(weights) > 1:
            weights[last] = 0.0
    except OSError:
        pass

    total = sum(weights.values()) or 1.0
    r = rnd() * total
    pick = pool[0]
    for s, w in weights.items():
        r -= w
        if r <= 0:
            pick = s
            break

    try:
        with open(LAST_FILE, "w") as f:
            f.write(pick)
    except OSError:
        pass
    print(pick)


if __name__ == "__main__":
    main()
