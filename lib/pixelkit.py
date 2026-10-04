"""pixelkit — placement-aware drawing helpers for the pixel canvas.

The GFX classic font is 5x7 on a 6x8 cell, scaled integerly: a char is
6*size px wide, 8*size tall. Nothing here draws blind: text measures
itself, clamps to the canvas, truncates with a ~ when it can't fit, and
can anchor left/center/right. Import from scene scripts:

    import sys, os
    sys.path.insert(0, os.path.expanduser("~/.dotfiles/lib"))
    from pixelkit import connect, skip
    cv = connect()
    cv.text("shipped today", 10, 15, color="mauve")
    cv.text("42 commits", y=225, color="dustrose", align="right")
    cv.para("a long title that wraps by measured width", 15, 55, size=2)
    cv.enter(dots, style="dither", secs=8)          # see pixelfx for the styles
    cv.enter_text("14:39", y=70, size=4, font="ocra", style="implode")
    cv.grow(x, y, w, h, "teal")                     # a bar rising from its base
    cv.type("words land one by one", 10, 100)

Every scene run is logged (one JSON line per run, on exit) to
~/.local/share/usage-logs/pixel/YYYY-MM-DD.jsonl — which scene, how it was
invoked, whether it drew, and the text it put on the glass. `pixel log`
reads it back. A scene with nothing to show calls skip("why"): it exits
SKIP so `pixel random` re-picks instead of wasting the rotation slot.
"""
import atexit
import hashlib
import json
import os
import random
import re
import signal
import socket
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime

W, H = 320, 240
CHAR_W, CHAR_H = 6, 8
MARGIN = 3

# pixel-live paints a 1s clock in the top-right corner (a black box from
# x=266 over rows 0-10). Text in that band stops short instead of being eaten.
TICKER_X, TICKER_H = 266, 11

SKIP = 3  # exit code: nothing to show, pick something else

# Reveal pacing. PIXEL_TEMPO scales every delay: 1 = normal, 0.5 = twice as
# fast, 0 = instant (previews, tests). STEPS_PER_SEC caps request rate during
# a reveal (~17ms/draw on the LAN). /batch measured 2026-10-03: 300 dots in
# 77ms, 600 in 137ms, 1000 in 222ms — 600/POST is past the knee.
try:
    TEMPO = max(0.0, float(os.environ.get("PIXEL_TEMPO", "1")))
except ValueError:
    TEMPO = 1.0
STEPS_PER_SEC = 24
GLYPHS = "0123456789ABCDEF#$%&*+=<>/\\|{}[]?!:;~^"  # decode() noise
BATCH_MAX = 600
EASE = {"linear": lambda t: t, "out": lambda t: 1 - (1 - t) ** 3}


def _sleep_until(deadline):
    """Deadline-based, so draw latency doesn't stretch the reveal."""
    left = deadline - time.monotonic()
    if left > 0:
        time.sleep(left)
LOG_DIR = os.environ.get("PIXEL_LOG_DIR") or os.path.expanduser("~/.local/share/usage-logs/pixel")


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


def ascii(s):
    """The device font is ASCII-only (no emoji, no arrows): drop the rest,
    collapse whitespace."""
    return re.sub(r"\s+", " ", re.sub(r"[^\x20-\x7e]", "", s or "")).strip()


def wrap(s, width):
    """Greedy word wrap to `width` chars; words longer than a line are split."""
    width = max(1, int(width))
    lines, cur = [], ""
    for w in s.split():
        while len(w) > width:
            if cur:
                lines.append(cur)
                cur = ""
            lines.append(w[:width])
            w = w[width:]
        if cur and len(cur) + 1 + len(w) > width:
            lines.append(cur)
            cur = w
        else:
            cur = f"{cur} {w}" if cur else w
    return lines + ([cur] if cur else [])


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
        self.shown = []  # text actually drawn, for the run log
        self.boxes = []  # (x0, y0, x1, y1) of drawn text/shapes: flyers pass behind
        _run["canvas"] = self
        if preflight:  # fail fast when the device is dark (one 0.8s probe)
            u = urllib.parse.urlparse(self.base)
            try:
                socket.create_connection((u.hostname, u.port or 80), timeout=0.8).close()
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
        for i in range(0, len(dots), BATCH_MAX):  # one POST per BATCH_MAX dots
            self._post(dots[i:i + BATCH_MAX])

    def _post(self, dots):
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

    # ── entrances ──────────────────────────────────────────────────────
    # Scenes draw themselves out over 5-20s: beat() paces sections, grow()
    # raises bars, type() lands words, enter()/enter_text() choreograph
    # dots (pixelfx: dither, print, sparkle, spiral, rain, implode...).
    # Order carries meaning: the spiral grows from its seed, the trace
    # sweeps toward now. Every delay is scaled by PIXEL_TEMPO (0 = instant).

    def beat(self, secs=0.25):
        """A pause between a scene's sections (frame, then data, then labels)."""
        if TEMPO > 0 and not self.dead:
            time.sleep(secs * TEMPO)

    def grow(self, x, y, w, h, color=None, rgb=None, secs=0.35, frm="bottom"):
        """A bar that rises from its base (frm="bottom") or extends rightward
        (frm="left"), eased out. Redraws the same color over itself, so it
        needs no erase."""
        steps = max(1, min(int(STEPS_PER_SEC * secs), int(h if frm == "bottom" else w)))
        if TEMPO <= 0 or self.dead:
            steps = 1
        t0 = time.monotonic()
        for k in range(1, steps + 1):
            f = EASE["out"](k / steps)
            if frm == "bottom":
                hh = max(1, round(h * f))
                self.rect(x, y + h - hh, w, hh, color=color, rgb=rgb)
            else:
                self.rect(x, y, max(1, round(w * f)), h, color=color, rgb=rgb)
            if steps > 1:
                _sleep_until(t0 + secs * TEMPO * k / steps)

    def enter(self, dots, style="dither", secs=8.0, bg=(0, 0, 0)):
        """Long-form entrance (pixelfx): dither, print, sparkle, spiral,
        order, or particle motion — rain / implode. bg = what's behind the
        flyers (an rgb, or f(x, y) -> rgb) so their trails get painted out."""
        import pixelfx
        pixelfx.enter(self, dots, style=style, secs=secs, bg=bg, tempo=TEMPO)

    def enter_text(self, msg, x=None, y=0, size=1, color="body", align="left",
                   style="implode", secs=6.0, font="gfx", bg=(0, 0, 0)):
        """Big type as moving dots. font: gfx (the device's own, pixel-exact),
        ocra, ocrb, micr (digits). Placement measured like text()."""
        import pixelfx
        msg = ascii(msg)
        right = TICKER_X - 2 if y < TICKER_H else W - MARGIN
        while msg and pixelfx.text_size(msg, size, font)[0] > right - MARGIN:
            msg = msg[:-1]  # trim to the glass (no ~: big type reads as a cut)
        if not msg:
            return None
        w = pixelfx.text_size(msg, size, font)[0]
        if align == "right":
            x = (right if x is None else min(x, right)) - w
        elif align == "center":
            x = (W // 2 if x is None else x) - w // 2
        elif x is None:
            x = MARGIN
        x = max(0, min(int(x), right - w))
        dots = pixelfx.text_dots(msg, x, int(y), size, rgb(color), font)
        pixelfx.enter(self, dots, style=style, secs=secs, bg=bg, tempo=TEMPO)
        self.shown.append(msg)
        self.boxes.append((x, int(y), x + w, int(y) + pixelfx.text_size(msg, size, font)[1]))
        return x

    def decode(self, msg, x=None, y=0, size=1, color="body", align="left", max_w=None,
               secs=1.6, noise="dkteal", bg=(0, 0, 0)):
        """text(), decrypted: every unlocked char churns through random
        glyphs, and they lock into `color` left to right over `secs`.
        Two GETs a frame (blank the unlocked cells, redraw noise)."""
        placed = self._place(msg, x, y, size, align, max_w)
        if not placed:
            return None
        msg, x, y = placed
        cw, ch = CHAR_W * size, CHAR_H * size
        put = lambda s, xx, c: self.get(f"text?msg={urllib.parse.quote(s, safe='')}"
                                        f"&x={xx}&y={y}&size={size}&color={c}")
        if TEMPO > 0 and not self.dead:
            frames = max(len(msg), int(12 * secs * TEMPO))  # 12fps churn, ~2 GETs/frame
            locked, t0 = 0, time.monotonic()
            for f in range(1, frames + 1):
                k = len(msg) * f // frames
                if k > locked:  # newly locked chars, in the real color
                    self.get(f"rect?x={x + locked * cw}&y={y}&w={(k - locked) * cw}&h={ch}"
                             f"&r={bg[0]}&g={bg[1]}&b={bg[2]}")
                    put(msg[locked:k], x + locked * cw, color)
                    locked = k
                if locked < len(msg):
                    self.get(f"rect?x={x + locked * cw}&y={y}&w={(len(msg) - locked) * cw}&h={ch}"
                             f"&r={bg[0]}&g={bg[1]}&b={bg[2]}")
                    put("".join(c if c == " " else random.choice(GLYPHS) for c in msg[locked:]),
                        x + locked * cw, noise)
                _sleep_until(t0 + secs * TEMPO * f / frames)
        else:
            put(msg, x, color)
        self.shown.append(msg)
        self.boxes.append((x, y, x + text_w(msg, size), y + ch))
        return x

    def type(self, msg, x=None, y=0, size=1, color="body", align="left", max_w=None,
             per_word=0.07):
        """text(), but the words land one at a time like a teleprinter.
        Placement is measured on the whole line first, so nothing shifts."""
        placed = self._place(msg, x, y, size, align, max_w)
        if not placed:
            return None
        msg, x, y = placed
        col = 0
        for word in msg.split(" "):
            if word:
                q = urllib.parse.quote(word, safe="")
                self.get(f"text?msg={q}&x={x + col * CHAR_W * size}&y={y}&size={size}&color={color}")
                self.beat(per_word)
            col += len(word) + 1
        self.shown.append(msg)
        self.boxes.append((x, y, x + text_w(msg, size), y + CHAR_H * size))
        return x

    def _place(self, msg, x, y, size, align, max_w):
        """Measure + clamp: (msg, x, y) as it will actually be drawn, or None."""
        msg = ascii(msg)
        right = TICKER_X - 2 if y < TICKER_H else W - MARGIN
        if align == "right":
            edge = right if x is None else min(x, right)
            avail = edge - MARGIN if max_w is None else min(max_w, edge - MARGIN)
            msg = fit(msg, avail, size)
            x = edge - text_w(msg, size)
        elif align == "center":
            cx = W // 2 if x is None else x
            avail = 2 * min(cx - MARGIN, right - cx) if max_w is None else max_w
            msg = fit(msg, avail, size)
            x = cx - text_w(msg, size) // 2
        else:
            if x is None:
                x = MARGIN
            avail = (right - x) if max_w is None else min(max_w, right - x)
            msg = fit(msg, avail, size)
        if not msg:
            return None
        return msg, max(0, min(int(x), W - 1)), max(0, min(int(y), H - CHAR_H * size))

    def text(self, msg, x=None, y=0, size=1, color="body", align="left", max_w=None):
        """Placement-aware text.

        align=left:   x is the left edge (default MARGIN)
        align=right:  x is the RIGHT edge to end at (default W - MARGIN)
        align=center: x is the center (default W/2)
        Truncates to max_w if given, and always to the canvas edge (or the
        live ticker's edge, in the top band).
        """
        placed = self._place(msg, x, y, size, align, max_w)
        if not placed:
            return None
        msg, x, y = placed
        q = urllib.parse.quote(msg, safe="")
        self.get(f"text?msg={q}&x={x}&y={y}&size={size}&color={color}")
        self.shown.append(msg)
        self.boxes.append((x, y, x + text_w(msg, size), y + CHAR_H * size))
        return x  # so callers can place accents relative to real position

    def para(self, msg, x=MARGIN, y=0, size=1, color="body", max_lines=None,
             line_h=None, max_w=None, typed=False, style=None, secs=8.0):
        """Word-wrapped block, measured to the space it has. Stops at
        max_lines or the bottom edge; leftover text ends the last line
        with ~ instead of silently vanishing. typed=True types it out word
        by word; style= ("print", "dither", "rain"...) enters the whole
        block as dots over `secs`. Returns the y below it."""
        line_h = line_h or (CHAR_H + 3) * size
        avail = W - MARGIN - x if max_w is None else min(max_w, W - MARGIN - x)
        lines = wrap(ascii(msg), avail // (CHAR_W * size))
        room = max(1, (H - y - CHAR_H * size) // line_h + 1)
        n = min(len(lines), room, max_lines or room)
        rows = []  # (line, y) as laid out
        for i, ln in enumerate(lines[:n]):
            if i == n - 1 and n < len(lines):
                ln = fit(f"{ln} {lines[n]}", avail, size)
            rows.append((ln, y))
            y += line_h
        if style:
            import pixelfx
            dots = []
            for ln, ly in rows:
                placed = self._place(ln, x, ly, size, "left", avail)
                if placed:
                    dots += pixelfx.text_dots(placed[0], placed[1], placed[2], size, rgb(color))
                    self.shown.append(placed[0])
            self.enter(dots, style=style, secs=secs)
        else:
            for ln, ly in rows:
                (self.type if typed else self.text)(ln, x, ly, size=size, color=color, max_w=avail)
        return y

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
        self.boxes.append((x, y, x + w, y + h))

    def circle(self, x, y, radius, color):
        r = int(radius)
        x = max(r, min(int(x), W - 1 - r))
        y = max(r, min(int(y), H - 1 - r))
        self.get(f"circle?x={x}&y={y}&radius={r}&color={color}")
        self.boxes.append((x - r, y - r, x + r + 1, y + r + 1))

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


# The device's full named palette (GET /info), for turning a color name into
# dots. VULPES above stays the subset hue_for() hashes over — growing it
# would reshuffle every repo's color.
PALETTE = {"pink": (230, 0, 103), "hotpink": (255, 26, 202), "magenta": (255, 51, 197),
           "rose": (255, 36, 171), "crimson": (255, 10, 137), "operator": (249, 44, 122),
           "red": (255, 16, 67), "teal": (110, 237, 247), "cyan": (160, 247, 252),
           "orange": (255, 170, 0), "yellow": (255, 210, 63), "green": (180, 212, 85),
           "dustrose": (196, 69, 105), "ansigreen": (106, 173, 138), "ansicyan": (94, 196, 196),
           "ansiblue": (168, 123, 181), "body": (242, 207, 223), "white": (245, 245, 245),
           "mauve": (115, 88, 101), "dkpink": (42, 21, 32), "dkteal": (26, 61, 66),
           "black": (0, 0, 0)}


def rgb(color):
    """Color name or (r, g, b) -> (r, g, b)."""
    return PALETTE.get(color, PALETTE["body"]) if isinstance(color, str) else tuple(color)


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def hue_for(name):
    """Stable color for a string (repo, session...) day to day.
    (hashlib, not hash() — python salts hash() per process.)"""
    keys = sorted(VULPES)
    n = int(hashlib.md5(name.encode()).hexdigest(), 16)
    return VULPES[keys[n % len(keys)]]


def dot(x, y, rgb, s=1):
    """One /batch entry: an s×s square at x,y."""
    return {"x": int(x), "y": int(y), "s": s, "r": rgb[0], "g": rgb[1], "b": rgb[2]}


def _claim_glass(base):
    """Newest scene wins: entrances run 10-20s, and a desk-event washaway or
    a new shell's greeting landing mid-animation would otherwise interleave
    two scenes' draws. Stop whoever holds this device's glass, then hold it.
    (Per host, so a test against a fake canvas never fights the real one.)"""
    host = re.sub(r"[^A-Za-z0-9.]", "_", urllib.parse.urlparse(base).netloc)
    glass = f"/tmp/pixel-scene-{host}.pid"
    try:
        old = int(open(glass).read())
        # pids get reused: only signal it if it's still a pixel scene
        if old != os.getpid() and "pixel-scenes/" in sh(["ps", "-p", str(old), "-o", "command="]):
            os.kill(old, signal.SIGTERM)
    except (OSError, ValueError):
        pass
    try:
        with open(glass, "w") as f:
            f.write(str(os.getpid()))
    except OSError:
        pass


def _preempted(signum, frame):
    _run["preempted"] = True
    sys.exit(0)


def connect():
    """Canvas for a scene: PIXEL_BASE env (set by the pixel wrapper) or the
    cached host, so pure-python scenes also run standalone. Takes the glass
    from any scene still animating."""
    # default host duplicated in lib/pixel-host.sh — change BOTH
    base = os.environ.get("PIXEL_BASE")
    if not base:
        host = os.environ.get("PIXEL_CANVAS_HOST")
        if not host:
            try:
                host = open(os.path.expanduser("~/.config/pixel-canvas-host")).read().strip()
            except OSError:
                host = "10.0.0.103"
        base = f"http://{host}"
    signal.signal(signal.SIGTERM, _preempted)
    _claim_glass(base)
    return Canvas(base)


def sh(cmd, timeout=5):
    """Run a command, return stdout ('' on any failure)."""
    try:
        return subprocess.run(cmd, capture_output=True, text=True,
                              timeout=timeout).stdout
    except Exception:
        return ""


def fetch(url, timeout=6):
    """GET a URL over the internet, body as text ('' on failure). Goes through
    curl: the python.org python3 here has no CA bundle, so urllib's HTTPS
    fails cert verification. (LAN draws to the canvas are plain HTTP.)"""
    return sh(["curl", "-sf", "--connect-timeout", "3", "--max-time", str(timeout), url],
              timeout=timeout + 2)


# ── run log ─────────────────────────────────────────────────────────────
_run = {"t0": time.time(), "canvas": None, "skip": None, "error": None}


def _crash(kind, value, tb):
    _run["error"] = f"{kind.__name__}: {value}"[:200]
    sys.__excepthook__(kind, value, tb)


sys.excepthook = _crash


def skip(reason):
    """Nothing to show right now (stale cache, empty feed): log why and exit
    SKIP so the rotation re-picks."""
    _run["skip"] = reason
    sys.exit(SKIP)


@atexit.register
def _log_run():
    cv = _run["canvas"]
    if cv is None and _run["skip"] is None and _run["error"] is None:
        return  # imported without drawing (previews, tests)
    e = {"ts": datetime.now().astimezone().isoformat(timespec="seconds"),
         "src": "pixel", "evt": "scene",
         "scene": os.path.basename(sys.argv[0]),
         "via": os.environ.get("PIXEL_VIA", "direct"),
         "ms": int((time.time() - _run["t0"]) * 1000)}
    if _run["skip"] is not None:
        e["skip"] = _run["skip"]
    if _run["error"] is not None:
        e["error"] = _run["error"]
    if _run.get("preempted"):
        e["preempted"] = True
    if cv is not None:
        e.update(ok=cv.ok, sent=cv.sent, failed=cv.failed, dead=cv.dead,
                 host=urllib.parse.urlparse(cv.base).netloc, text=cv.shown[:16])
    try:
        os.makedirs(LOG_DIR, exist_ok=True)
        with open(os.path.join(LOG_DIR, time.strftime("%Y-%m-%d") + ".jsonl"), "a") as f:
            f.write(json.dumps(e) + "\n")
    except OSError:
        pass
