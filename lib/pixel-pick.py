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
    if 5 <= hour < 11:      # morning: opening credits, then the day's step
        return {"greeting": 3, "email": 3, "todos": 3, "weather": 2, "commits": 1,
                "action": 3, "tally": 2, "credits": 4}
    if 11 <= hour < 17:     # workday: the hive and the monitor
        return {"fleet": 2, "commits": 2, "wpm": 2, "rescuetime": 2, "email": 1,
                "action": 1, "knock": 1, "found": 1, "hive": 2, "vitals": 1}
    if 17 <= hour < 22:     # evening: the city lights up
        return {"reading": 3, "last-film": 2, "now-playing": 2, "said": 2, "bloom": 1,
                "found": 2, "wilt": 2, "held": 1, "skyline": 3, "transmission": 1}
    return {"cipher": 2, "constellation": 2, "ambient-dots": 2,  # late night
            "foundation": 1, "clock": 1, "knock": 1,
            "skyline": 3, "transmission": 2, "hive": 1}


def brief_boosts():
    """scene -> extra tickets from the morning brief's facts (brief.json)."""
    try:
        with open(os.path.join(HOME, ".local/state/pixel/brief.json")) as f:
            b = json.load(f)
    except Exception:
        return {}
    out = {}
    if any(i.get("new") and i.get("hits", 0) >= 300 and i.get("kind") == "scanner"
           for i in b.get("ips") or []):
        out["knock"] = 4                      # a new heavy scanner showed up
    fnd = b.get("found") or {}
    if any(fnd.get(k) for k in ("stars", "forks", "referrers_new", "mentions")):
        out["found"] = 5                      # someone new found you
    if (b.get("action") or {}).get("nudge") == "loud":
        out["action"] = 2
        out["wilt"] = 2                       # a goal has gone silent
    if any(c.get("days", 0) >= 90 for c in b.get("kanban_blocked") or []):
        out["tally"] = 1
    return out


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

    # the brief's facts: new scanners, someone found you, silent goals, old blocks
    for s, boost in brief_boosts().items():
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

    # chart-desk making slot is open (from slot start until `desk shipped`) -> the bench
    # takes over. Louder than fleet; the never-repeat rule still interleaves others.
    try:
        with open(os.path.join(HOME, ".local/state/chart-desk/bench.json")) as f:
            b = json.load(f)
        if b.get("date") == time.strftime("%Y-%m-%d") and b.get("dir") and not b.get("shipped_today") \
                and time.strftime("%H:%M") >= b.get("slot_start", "09:00") and "bench" in weights:
            weights["bench"] += 12
    except Exception:
        pass

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
