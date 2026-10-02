"""Was EJ at the desk? — presence for the muse wall's taste learning.

Why: 53% of renders happened in hours that never got a star (he was asleep or
away), so "unstarred" mostly meant "unseen" and the star weights learned his
schedule (Fable review, 2026-09-30). Labels now only count renders he could
have seen.

Presence = a HUMAN event within RADIUS seconds, from ~/.local/share/usage-logs:
  modifiers (keypresses) · tmux (pane switches) · shell (commands) · nvim ·
  talon (voice) · claude (UserPromptSubmit only — tool calls are the agent) ·
  presence (HIDIdleTime samples the muse-loop writes each cell; idle < RADIUS)
Window snapshots are skipped: their "periodic" trigger fires unattended.

A render is SEEN if presence overlaps its time ON THE WALL: from its own
timestamp until the next render in the same slot (capped at MAX_ON seconds).
"""
import bisect, datetime as dt, glob, json, os, re

LOGS = os.path.expanduser("~/.local/share/usage-logs")
RADIUS = int(os.environ.get("MUSE_PRESENCE_RADIUS", "300"))
MAX_ON = int(os.environ.get("MUSE_PRESENCE_MAX_ON", "1800"))
STREAMS = ("modifiers", "tmux", "shell", "nvim", "talon", "claude", "presence")

def _epoch(ts):
    """ISO with Z / ±hh:mm offset, or naive local → epoch seconds."""
    ts = ts.strip().replace("Z", "+00:00")
    d = dt.datetime.fromisoformat(ts)
    return d.timestamp()  # naive → interpreted as local time

def events(since_day="2026-09-01"):
    """Sorted epoch seconds of human activity."""
    out = []
    for s in STREAMS:
        for f in sorted(glob.glob(f"{LOGS}/{s}/*.jsonl")):
            if os.path.basename(f)[:10] < since_day:
                continue
            for line in open(f, errors="replace"):
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                if s == "claude" and e.get("event") != "UserPromptSubmit":
                    continue
                if s == "presence" and float(e.get("idle_s", 1e9)) >= RADIUS:
                    continue
                try:
                    out.append(_epoch(e["ts"]))
                except (KeyError, ValueError, TypeError):
                    continue
    out.sort()
    return out

def present_during(ev, start, end):
    """Any human event in [start - RADIUS, end + RADIUS]?"""
    i = bisect.bisect_left(ev, start - RADIUS)
    return i < len(ev) and ev[i] <= end + RADIUS

def slot_of(rid):
    m = re.search(r"-c(\d+)$", rid)
    return int(m.group(1)) if m else None

def seen_flags(rows, ev=None):
    """rows: dicts with 'id' and 'ts' (naive local ISO). → {id: True/False};
    renders without a timestamp are left out (unknown, never a negative)."""
    ev = ev if ev is not None else events()
    by_slot = {}
    for r in rows:
        if r.get("ts"):
            by_slot.setdefault(slot_of(r["id"]), []).append((_epoch(r["ts"]), r["id"]))
    flags = {}
    for lst in by_slot.values():
        lst.sort()
        for k, (t, rid) in enumerate(lst):
            nxt = lst[k + 1][0] if k + 1 < len(lst) else t + MAX_ON
            flags[rid] = present_during(ev, t, min(nxt, t + MAX_ON))
    return flags
