"""sitestats — ejfox.com/api/stats (letterboxd, last.fm, goodreads,
monkeytype, rescuetime...) for pixel scenes. Cached 5 min in /tmp so scenes
firing back to back share one fetch; a failed fetch falls back to the stale
cache rather than nothing.

    from sitestats import stats, dig
    s = stats()                                   # {} when unavailable
    dig(s, "letterboxd", "films", 0, "title")     # None on any missing step
"""
import json
import os
import time

from pixelkit import fetch

URL = "https://ejfox.com/api/stats"
CACHE = "/tmp/ejfox-stats.json"
MAX_AGE = 300


def _fresh():
    try:
        return time.time() - os.path.getmtime(CACHE) < MAX_AGE
    except OSError:
        return False


def stats():
    if not _fresh():
        try:
            body = fetch(URL, timeout=8)
            json.loads(body)  # only replace the cache with valid JSON
            tmp = f"{CACHE}.{os.getpid()}"
            with open(tmp, "w") as f:
                f.write(body)
            os.replace(tmp, CACHE)
        except Exception:
            pass
    try:
        with open(CACHE) as f:
            return json.load(f)
    except Exception:
        return {}


def dig(d, *path):
    """Walk dict keys / list indexes; None as soon as a step is missing."""
    for k in path:
        try:
            d = d[k]
        except (KeyError, IndexError, TypeError):
            return None
    return d
