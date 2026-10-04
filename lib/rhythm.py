"""rhythm — EJ's real daily rhythms from local logs, for the theater scenes
(skyline, vitals, credits, transmission, hive). Local files only, no network.

Sources (~/.local/share/usage-logs/<stream>/YYYY-MM-DD.jsonl):
  claude    hook events: UserPromptSubmit, PostToolUse, PostToolUseFailure, SubagentStop, Stop
  presence  {"ts","idle_s"} every ~2.5 min
  talon     {"evt":"phrase","text","words","app"} spoken dictation
plus git across ~/code.
"""
import json
import math
import os
import subprocess
from datetime import datetime, timedelta, timezone

LOGS = os.path.expanduser("~/.local/share/usage-logs")
CODE = os.path.expanduser("~/code")
LAT, LON = 41.5, -74.0  # Hudson Valley


def parse_ts(s):
    """ISO8601 with Z, offset, or naive-local → aware datetime."""
    try:
        s = s.replace("Z", "+00:00")
        if len(s) >= 5 and (s[-5] in "+-") and s[-3] != ":":  # -0400 → -04:00
            s = s[:-2] + ":" + s[-2:]
        d = datetime.fromisoformat(s)
        return d if d.tzinfo else d.astimezone()
    except Exception:
        return None


def events(stream, days=1):
    """Events from the last `days` local days (today included), oldest first."""
    out = []
    for back in range(days, -1, -1):
        day = (datetime.now() - timedelta(days=back)).strftime("%Y-%m-%d")
        try:
            with open(os.path.join(LOGS, stream, f"{day}.jsonl")) as f:
                for line in f:
                    try:
                        e = json.loads(line)
                    except ValueError:
                        continue
                    t = parse_ts(e.get("ts", ""))
                    if t:
                        e["_t"] = t
                        out.append(e)
        except OSError:
            pass
    return out


def since(evts, hours):
    cut = datetime.now(timezone.utc) - timedelta(hours=hours)
    return [e for e in evts if e["_t"] >= cut]


def claude_last(hours=24):
    return since(events("claude", 2), hours)


def awake_hours():
    """Hours since the last idle stretch of 2h+ ended (≈ since you woke).
    A 2h+ hole in the presence log counts as idle too: the logger is silent
    while the Mac sleeps, so the overnight stretch often isn't logged at all."""
    pres = since(events("presence", 2), 36)
    last_long_idle_end = None
    prev = None
    for e in pres:
        gap = (e["_t"] - prev).total_seconds() if prev else 0
        if e.get("idle_s", 0) >= 7200 or gap >= 7200:
            last_long_idle_end = e["_t"]
        prev = e["_t"]
    if not last_long_idle_end:
        return None
    return (datetime.now(timezone.utc) - last_long_idle_end).total_seconds() / 3600


def git_by_repo(days=30):
    """{repo: (commits_in_days, commits_last_24h)} for repos with any commits."""
    out = {}
    if not os.path.isdir(CODE):
        return out
    now = datetime.now().timestamp()
    for d in sorted(os.listdir(CODE)):
        p = os.path.join(CODE, d)
        if not os.path.isdir(os.path.join(p, ".git")):
            continue
        try:
            r = subprocess.run(["git", "-C", p, "log", "--all", f"--since={days}.days",
                                "--format=%ct"], capture_output=True, text=True, timeout=4)
            ts = [int(x) for x in r.stdout.split()]
        except Exception:
            continue
        if ts:
            out[d] = (len(ts), sum(1 for t in ts if now - t < 86400))
    return out


def sun_altitude(when=None):
    """Solar elevation in degrees at LAT/LON (NOAA-ish approximation, ±1°)."""
    t = when or datetime.now(timezone.utc)
    doy = t.timetuple().tm_yday
    hr = t.hour + t.minute / 60
    g = 2 * math.pi / 365 * (doy - 1 + (hr - 12) / 24)
    decl = (0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g)
            - 0.006758 * math.cos(2 * g) + 0.000907 * math.sin(2 * g))
    eqt = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g)
                    - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g))
    tst = hr * 60 + eqt + 4 * LON
    ha = math.radians(tst / 4 - 180)
    lat = math.radians(LAT)
    cosz = math.sin(lat) * math.sin(decl) + math.cos(lat) * math.cos(decl) * math.cos(ha)
    return 90 - math.degrees(math.acos(max(-1, min(1, cosz))))


def moon_phase(when=None):
    """0 = new, 0.5 = full, 1 = new again (synodic month from a known new moon)."""
    t = when or datetime.now(timezone.utc)
    ref = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    return ((t - ref).total_seconds() / 86400 / 29.530588853) % 1.0


def robots_working():
    """◆N from `robots -t` = agents working right now."""
    try:
        r = subprocess.run([os.path.expanduser("~/.dotfiles/bin/robots"), "-t"],
                           capture_output=True, text=True, timeout=3).stdout
        return int(r.split("◆")[1].split()[0]) if "◆" in r else 0
    except Exception:
        return 0

