"""pixelkit — placement-aware drawing helpers for the pixel canvas.

The GFX classic font is 5x7 on a 6x8 cell, scaled integerly: a char is
6*size px wide, 8*size tall. Nothing here draws blind: text measures
itself, clamps to the canvas, truncates with a ~ when it can't fit, and
can anchor left/center/right. Import from scene scripts:

    import sys, os
    sys.path.insert(0, os.path.expanduser("~/.dotfiles/lib"))
    from pixelkit import Canvas
    cv = Canvas(BASE)
    cv.text("shipped today", 10, 15, color="mauve")
    cv.text("42 commits", y=225, color="dustrose", align="right")
    cv.text("centered", y=118, color="body", align="center")
"""
import json
import urllib.parse
import urllib.request

W, H = 320, 240
CHAR_W, CHAR_H = 6, 8
MARGIN = 3


def text_w(msg, size=1):
    return len(msg) * CHAR_W * size


def fit(msg, max_w, size=1):
    """Truncate msg to max_w px, marking the cut with a trailing ~."""
    max_chars = max(0, int(max_w) // (CHAR_W * size))
    if len(msg) <= max_chars:
        return msg
    if max_chars < 2:
        return msg[:max_chars]
    return msg[: max_chars - 1] + "~"


class Canvas:
    """Draw calls never raise (scenes must be hook-safe), but they are
    counted: .sent / .failed, and .ok is False when nothing landed —
    scenes can `sys.exit(0 if cv.ok else 1)` to make failures visible."""

    def __init__(self, base, timeout=3, preflight=True):
        self.base = base.rstrip("/")
        self.timeout = timeout
        self.sent = 0
        self.failed = 0
        self.dead = False
        if preflight:  # fail fast when the device is dark (one 0.8s probe)
            import socket, urllib.parse as _p
            host = _p.urlparse(self.base).hostname
            try:
                socket.create_connection((host, 80), timeout=0.8).close()
            except OSError:
                self.dead = True

    @property
    def ok(self):
        return self.sent > 0 and self.failed < self.sent

    def get(self, path):
        if self.dead:
            self.failed += 1
            return
        try:
            urllib.request.urlopen(f"{self.base}/{path}", timeout=self.timeout).read()
            self.sent += 1
        except Exception:
            self.failed += 1

    def batch(self, dots):
        if self.dead:
            self.failed += 1
            return
        try:
            req = urllib.request.Request(
                f"{self.base}/batch", data=json.dumps(dots).encode(),
                headers={"Content-Type": "application/json"})
            urllib.request.urlopen(req, timeout=self.timeout + 1).read()
            self.sent += 1
        except Exception:
            self.failed += 1

    def clear(self, color=None):
        self.get(f"clear?color={color}" if color else "clear")

    def text(self, msg, x=None, y=0, size=1, color="body", align="left", max_w=None):
        """Placement-aware text.

        align=left:   x is the left edge (default MARGIN)
        align=right:  x is the RIGHT edge to end at (default W - MARGIN)
        align=center: x is the center (default W/2)
        Truncates to max_w if given, and always to the canvas edge.
        """
        if align == "right":
            edge = W - MARGIN if x is None else x
            avail = edge - MARGIN if max_w is None else min(max_w, edge - MARGIN)
            msg = fit(msg, avail, size)
            x = edge - text_w(msg, size)
        elif align == "center":
            cx = W // 2 if x is None else x
            avail = 2 * min(cx - MARGIN, W - MARGIN - cx) if max_w is None else max_w
            msg = fit(msg, avail, size)
            x = cx - text_w(msg, size) // 2
        else:
            if x is None:
                x = MARGIN
            avail = (W - MARGIN - x) if max_w is None else min(max_w, W - MARGIN - x)
            msg = fit(msg, avail, size)
        if not msg:
            return None
        x = max(0, min(int(x), W - 1))
        y = max(0, min(int(y), H - CHAR_H * size))
        q = urllib.parse.quote(msg, safe="")
        self.get(f"text?msg={q}&x={x}&y={y}&size={size}&color={color}")
        return x  # so callers can place accents relative to real position

    def rect(self, x, y, w, h, color=None, rgb=None):
        x, y = max(0, int(x)), max(0, int(y))
        w = min(int(w), W - x)
        h = min(int(h), H - y)
        if w <= 0 or h <= 0:
            return
        if rgb:
            self.get(f"rect?x={x}&y={y}&w={w}&h={h}&r={rgb[0]}&g={rgb[1]}&b={rgb[2]}")
        else:
            self.get(f"rect?x={x}&y={y}&w={w}&h={h}&color={color}")

    def circle(self, x, y, radius, color):
        r = int(radius)
        x = max(r, min(int(x), W - 1 - r))
        y = max(r, min(int(y), H - 1 - r))
        self.get(f"circle?x={x}&y={y}&radius={r}&color={color}")

    def line(self, x1, y1, x2, y2, color):
        c = lambda v, hi: max(0, min(int(v), hi - 1))
        self.get(f"line?x1={c(x1,W)}&y1={c(y1,H)}&x2={c(x2,W)}&y2={c(y2,H)}&color={color}")


# ── scene conveniences ──────────────────────────────────────────────────
GOLDEN = 2.39996322972865332  # golden angle, radians

VULPES = {"pink": (0xe6, 0x00, 0x67), "teal": (0x6e, 0xed, 0xf7),
          "hotpink": (0xff, 0x1a, 0xca), "red": (0xff, 0x10, 0x43),
          "orange": (0xff, 0xaa, 0x00), "green": (0xb4, 0xd4, 0x55),
          "cyan": (0xa0, 0xf7, 0xfc), "magenta": (0xff, 0x33, 0xc5),
          "ansiblue": (0xa8, 0x7b, 0xb5), "ansicyan": (0x5e, 0xc4, 0xc4),
          "dustrose": (0xc4, 0x45, 0x69), "white": (0xf5, 0xf5, 0xf5)}


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def hue_for(name):
    """Stable color for a string (repo, session...) day to day.
    (hashlib, not hash() — python salts hash() per process.)"""
    import hashlib
    keys = sorted(VULPES)
    n = int(hashlib.md5(name.encode()).hexdigest(), 16)
    return VULPES[keys[n % len(keys)]]


def connect():
    """Canvas for a scene: PIXEL_BASE env (set by the pixel wrapper) or the
    cached host, so pure-python scenes also run standalone."""
    import os
    base = os.environ.get("PIXEL_BASE")
    if not base:
        host = os.environ.get("PIXEL_CANVAS_HOST")
        if not host:
            try:
                host = open(os.path.expanduser("~/.config/pixel-canvas-host")).read().strip()
            except OSError:
                host = "10.0.0.103"
        base = f"http://{host}"
    return Canvas(base)


def sh(cmd, timeout=5):
    """Run a command, return stdout ('' on any failure)."""
    import subprocess
    try:
        return subprocess.run(cmd, capture_output=True, text=True,
                              timeout=timeout).stdout
    except Exception:
        return ""
