#!/usr/bin/env python3
"""pixel-log — read back what the canvas showed (usage-logs/pixel).

    pixel log          last 20 events today, newest last
    pixel log 50       last 50 events today
    pixel log today    per-scene tally for today: shown / skipped / failed
    pixel log week     the same tally over the last 7 days

Events (one JSON line each, written by pixel-pick, pixelkit, pixel say,
desk-event): pick {scene, odds, why}, scene {scene, via, ok, skip, ms, text},
say {text}, caption {kind, text}.
"""
import json
import os
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta

LOG_DIR = os.environ.get("PIXEL_LOG_DIR") or os.path.expanduser("~/.local/share/usage-logs/pixel")


def load(days):
    out = []
    for back in range(days - 1, -1, -1):
        day = (datetime.now() - timedelta(days=back)).strftime("%Y-%m-%d")
        try:
            with open(os.path.join(LOG_DIR, f"{day}.jsonl")) as f:
                out += [json.loads(l) for l in f if l.strip()]
        except (OSError, ValueError):
            pass
    return out


def hhmm(e):
    return e.get("ts", "")[11:16]


def recent(n):
    for e in load(1)[-n:]:
        evt = e.get("evt")
        if evt == "pick":
            why = ", ".join(e.get("why") or []) or "base ticket"
            print(f"{hhmm(e)}  pick    {e['scene']:<14} {e.get('odds', 0):>4.0%}  {why}")
        elif evt == "scene":
            if "error" in e:
                status = f"CRASH {e['error']}"
            elif "skip" in e:
                status = f"skip: {e['skip']}"
            elif e.get("preempted"):
                status = "cut off mid-entrance by a newer scene"
            elif e.get("dead"):
                status = "device dark"
            elif not e.get("ok"):
                status = f"FAILED {e.get('failed')}/{e.get('sent', 0) + e.get('failed', 0)} draws"
            else:
                status = " | ".join(e.get("text") or []) or "(no text)"
            print(f"{hhmm(e)}  {e.get('via', '?'):<7} {e['scene']:<14} {e.get('ms', 0) / 1000:>4.1f}s {status}"[:160])
        else:
            print(f"{hhmm(e)}  {evt:<7} {e.get('kind', '')} {e.get('text', '')}"[:160])


def tally(days):
    shown, skipped, failed, reasons = Counter(), Counter(), Counter(), defaultdict(Counter)
    for e in load(days):
        if e.get("evt") != "scene":
            continue
        s = e["scene"]
        if "skip" in e:
            skipped[s] += 1
            reasons[s][e["skip"]] += 1
        elif e.get("ok") and "error" not in e:
            shown[s] += 1
        else:
            failed[s] += 1
    scenes = sorted(set(shown) | set(skipped) | set(failed), key=lambda s: -shown[s])
    if not scenes:
        print("no scene runs logged yet")
        return
    print(f"{'scene':<14} {'shown':>5} {'skip':>5} {'fail':>5}  top skip reason")
    for s in scenes:
        top = reasons[s].most_common(1)
        print(f"{s:<14} {shown[s]:>5} {skipped[s]:>5} {failed[s]:>5}  {top[0][0] if top else ''}"[:120])


arg = sys.argv[1] if len(sys.argv) > 1 else ""
if arg == "today":
    tally(1)
elif arg == "week":
    tally(7)
else:
    recent(int(arg) if arg.isdigit() else 20)
