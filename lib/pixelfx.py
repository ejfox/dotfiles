"""pixelfx — long entrances (5-20s) for pixel scenes. A scene's marks arrive
pixel by pixel, still through the /batch straw: no frame blitting, just a
choreography over the dots a scene was going to draw anyway.

    cv.enter(dots, style="dither", secs=8)
    cv.enter_text("14:39", y=85, size=5, color="pink", align="center", style="implode")

Styles
  order    the scene's own list order (spiral from the seed, sweep to now)
  print    top-to-bottom scan, like a receipt printer head
  rise     bottom-to-top, everything growing at once (stems, a field)
  dither   ordered 8x8 Bayer dither: the image resolves through a lattice
  sparkle  pixel by pixel, random order
  spiral   swept outward along a spiral arm from the middle
  rain     each mark falls from the top and lands, accelerating
  implode  marks start scattered across the screen and fly home (de-explode)
  interlace  even rows, then odd rows: an interlaced broadcast field
  scanline a bright beam sweeps down with an afterglow; the image is behind it
  crt      CRT power-on: a white line flashes mid-screen, the image opens out
           vertically from it behind two beams
  glitch   bands arrive torn sideways with an RGB split (hotpink/cyan ghosts),
           hold a frame, then snap into place

The beam / glitch styles only touch the region the dots occupy, and skip
anything already drawn there (cv.boxes), so headers never get scarred.
Text can also decode (Canvas.decode): every char churns through random
glyphs and locks in left to right.

rain/implode are real particle motion: every frame repaints the flyers at
their new spot and paints the background over where they just were. The
device sustains ~3.9k dots/s (300/POST in ~77ms, measured 2026-10-03), so
~150 flyers at once at ~12 fps; past that, the extras pop in on schedule.

text_dots() rasterizes text so big type can move too: font="gfx" is the
device's own font (Adafruit GFX classic 5x7 via LovyanGFX glcdfont.h, BSD)
and lands pixel-identical to /text; "ocra" / "ocrb" / "micr" are the 1960s
machine-reading faces (OCR-A, OCR-B, MICR E-13B check digits).
"""
import math
import os
import random
import time

FPS = 12
MAX_FLYERS = 150  # concurrent particles that fit the device's dots/s budget

STYLES = ("order", "print", "rise", "dither", "sparkle", "spiral", "rain", "implode",
          "interlace", "scanline", "crt", "glitch")
BEAM = (245, 245, 245)       # scanline head
GLOW = (26, 61, 66)          # afterglow row (dkteal)
GHOSTS = ((255, 26, 202), (160, 247, 252))   # glitch RGB split: hotpink / cyan

# Adafruit GFX classic font, printable ASCII 32..126: 5 column bytes per
# glyph, bit 0 = top row. (glcdfont.h bytes 160..634)
_FONT = bytes.fromhex(
    "000000000000005f00000007000700147f147f14242a7f2a12231308646236495620500008070300"
    "001c2241000041221c002a1c7f1c2a08083e08080080703000080808080800006060002010080402"
    "3e5149453e00427f400072494949462141494d331814127f1027454545393c4a4949314121110907"
    "3649494936464949291e000014000000403400000008142241141414141400412214080201590906"
    "3e415d594e7c1211127c7f494949363e414141227f4141413e7f494949417f090909013e41415173"
    "7f0808087f00417f41002040413f017f081422417f404040407f021c027f7f0408107f3e4141413e"
    "7f090909063e4151215e7f09192946264949493203017f01033f4040403f1f2040201f3f4038403f"
    "631408146303047804036159494d43007f4141410204081020004141417f04020102044040404040"
    "000307080020545478407f284444383844444428384444287f385454541800087e090218a4a49c78"
    "7f0804047800447d40002040403d007f1028440000417f40007c047804787c080404783844444438"
    "fc1824241818242418fc7c08040408485454542404043f44243c4040207c1c2040201c3c4030403c"
    "44281028444c9090907c4464544c440008364100000077000000413608000201020402")

_BAYER = [[0, 32, 8, 40, 2, 34, 10, 42], [48, 16, 56, 24, 50, 18, 58, 26],
          [12, 44, 4, 36, 14, 46, 6, 38], [60, 28, 52, 20, 62, 30, 54, 22],
          [3, 35, 11, 43, 1, 33, 9, 41], [51, 19, 59, 27, 49, 17, 57, 25],
          [15, 47, 7, 39, 13, 45, 5, 37], [63, 31, 55, 23, 61, 29, 53, 21]]


# OCR faces, rasterized 1-bit at the pixel size where each is crisp, then
# scaled by `size` like the device font (chunky on purpose). See
# lib/pixel-fonts/README.md for sources + licenses.
FONT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pixel-fonts")
FACES = {"ocra": ("OCRA.otf", 11), "ocrb": ("ocrb10.otf", 15), "micr": ("GnuMICR.ttf", 16)}
FONTS = ("gfx",) + tuple(FACES)
_faces = {}


def _face(font):
    if font not in _faces:
        from PIL import ImageFont
        path, px = FACES[font]
        _faces[font] = ImageFont.truetype(os.path.join(FONT_DIR, path), px)
    return _faces[font]


def text_size(msg, size=1, font="gfx"):
    """(width, height) in canvas px that text_dots will cover."""
    if font == "gfx":
        return len(msg) * 6 * size, 8 * size
    f = _face(font)
    asc, desc = f.getmetrics()
    return int(math.ceil(f.getlength(msg))) * size, (asc + desc) * size


def text_dots(msg, x, y, size, rgb, font="gfx"):
    """Text as dots. font="gfx" matches the device's drawString exactly; the
    OCR faces are rasterized here. Each font pixel is a size x size square."""
    if font != "gfx":
        from PIL import Image, ImageDraw
        w, h = text_size(msg, 1, font)
        img = Image.new("L", (max(1, w), max(1, h)))
        d = ImageDraw.Draw(img)
        d.fontmode = "1"  # no antialiasing: hard pixels only
        d.text((0, 0), msg, font=_face(font), fill=255)
        px = img.load()
        return [{"x": x + i * size, "y": y + j * size, "s": size,
                 "r": rgb[0], "g": rgb[1], "b": rgb[2]}
                for j in range(img.height) for i in range(img.width) if px[i, j]]
    dots = []
    for i, ch in enumerate(msg):
        c = ord(ch) - 32
        if not 0 <= c < 95:
            continue
        for col in range(5):
            bits = _FONT[c * 5 + col]
            for row in range(8):
                if bits >> row & 1:
                    dots.append({"x": x + (i * 6 + col) * size, "y": y + row * size, "s": size,
                                 "r": rgb[0], "g": rgb[1], "b": rgb[2]})
    return dots


def rect_dots(x, y, w, h, rgb, s=4):
    """A filled rect as an s-px dot grid, so a background can dither in too."""
    return [{"x": xx, "y": yy, "s": s, "r": rgb[0], "g": rgb[1], "b": rgb[2]}
            for yy in range(y, y + h, s) for xx in range(x, x + w, s)]


def _order(dots, style, rng):
    if style == "order":
        return list(dots)
    if style == "print":
        return sorted(dots, key=lambda d: (d["y"], d["x"]))
    if style == "rise":
        return sorted(dots, key=lambda d: (-d["y"], rng.random()))
    if style == "interlace":
        return sorted(dots, key=lambda d: ((d["y"] // d.get("s", 1)) % 2, d["y"], d["x"]))
    if style == "dither":
        return sorted(dots, key=lambda d: (_BAYER[d["y"] // d.get("s", 1) % 8][d["x"] // d.get("s", 1) % 8],
                                           rng.random()))
    if style == "spiral":
        cx = sum(d["x"] for d in dots) / len(dots)
        cy = sum(d["y"] for d in dots) / len(dots)
        R = max(math.hypot(d["x"] - cx, d["y"] - cy) for d in dots) or 1

        def arm(d):  # position along a 3-turn spiral arm
            r = math.hypot(d["x"] - cx, d["y"] - cy) / R
            a = (math.atan2(d["y"] - cy, d["x"] - cx) + math.pi) / (2 * math.pi)
            return math.floor(r * 3 - a) + a
        return sorted(dots, key=arm)
    out = list(dots)  # sparkle, and the launch order for rain/implode
    rng.shuffle(out)
    return out


def _bg_of(bg):
    return bg if callable(bg) else (lambda x, y: bg)


def enter(cv, dots, style="dither", secs=8.0, bg=(0, 0, 0), tempo=1.0):
    """Choreograph dots onto the canvas over ~secs seconds (scaled by tempo)."""
    if not dots:
        return
    if tempo <= 0 or cv.dead:
        return cv.batch(dots)
    rng = random.Random()
    seq = _order(dots, style, rng)
    total = secs * tempo
    if style in ("rain", "implode"):
        return _fly(cv, seq, style, total, _bg_of(bg), rng)
    if style in ("scanline", "crt"):
        return _beam(cv, seq, style, total, _bg_of(bg))
    if style == "glitch":
        return _glitch(cv, seq, total, _bg_of(bg), rng)
    steps = max(1, int(min(FPS * total, len(seq))))
    t0, done = time.monotonic(), 0
    for k in range(1, steps + 1):
        upto = round(len(seq) * k / steps)
        if upto > done:
            cv.batch(seq[done:upto])
            done = upto
        _sleep_until(t0 + total * k / steps)


def _fly(cv, seq, style, total, bg, rng):
    frames = max(2, int(FPS * total))
    flight = max(3, min(int(FPS * 1.2), frames // 3))         # ~1.2s in the air
    n = len(seq)
    # more marks than the dots/s budget can move: the extras pop in on schedule
    fly_share = min(1.0, MAX_FLYERS * frames / (n * flight))
    plan = []
    for i, d in enumerate(seq):
        launch = int(i / n * (frames - flight))
        if rng.random() >= fly_share:
            plan.append((launch + flight, d, None))           # lands without flying
            continue
        if style == "rain":
            start = (d["x"] + rng.randint(-3, 3), rng.randint(0, max(0, d["y"] // 6)))
        else:  # implode: from anywhere on the glass
            start = (rng.randrange(0, 316), rng.randrange(0, 236))
        plan.append((launch, d, start))
    landed = set()
    prev = []  # flyer squares painted last frame: (x, y, s)
    boxes = list(getattr(cv, "boxes", []))  # already-drawn content: fly BEHIND it
    behind = lambda x, y, s: _behind(boxes, x, y, s)
    t0 = time.monotonic()
    for f in range(frames + flight + 1):
        paint, now = [], []
        for launch, d, start in plan:
            if start is None:
                if f == launch:
                    paint.append(d)
                    landed.add((d["x"], d["y"]))
                continue
            t = (f - launch) / flight
            if t < 0 or t > 1 + 1 / flight:
                continue
            if t >= 1:
                paint.append(d)
                landed.add((d["x"], d["y"]))
                continue
            e = t * t if style == "rain" else 1 - (1 - t) ** 3   # gravity / settle
            x = int(start[0] + (d["x"] - start[0]) * e)
            y = int(start[1] + (d["y"] - start[1]) * e)
            if behind(x, y, d.get("s", 1)):
                continue  # passing behind text/shapes: neither paint nor erase
            now.append((x, y, d.get("s", 1)))
            paint.append({**d, "x": x, "y": y})
        here = set(now)
        erase = [(x, y, s) for x, y, s in prev if (x, y, s) not in here and (x, y) not in landed]
        cv.batch([{"x": x, "y": y, "s": s, "r": c[0], "g": c[1], "b": c[2]}
                  for x, y, s in erase for c in [bg(x, y)]] + paint)
        prev = now
        _sleep_until(t0 + total * (f + 1) / frames)


def _bbox(dots):
    return (min(d["x"] for d in dots), min(d["y"] for d in dots),
            max(d["x"] + d.get("s", 1) for d in dots), max(d["y"] + d.get("s", 1) for d in dots))


def _behind(boxes, x, y, s):
    return any(x < bx1 and x + s > bx0 and y < by1 and y + s > by0
               for bx0, by0, bx1, by1 in boxes)


def _hline(cv, y, x0, x1, rgb, boxes):
    """A 1px row across x0..x1 as /rect calls, split around anything already
    drawn on that row — the beam passes over text, never through it.
    (Raw GETs: beam rows are transient, so they don't join cv.boxes.)"""
    segs = [(x0, x1)]
    for bx0, by0, bx1, by1 in boxes:
        if by0 <= y < by1:
            segs = [part for a, b in segs
                    for part in (((a, b),) if bx1 <= a or bx0 >= b else
                                 ((a, min(b, bx0)), (max(a, bx1), b)))
                    if part[1] > part[0]]
    for a, b in segs:
        cv.get(f"rect?x={a}&y={y}&w={b - a}&h=1&r={rgb[0]}&g={rgb[1]}&b={rgb[2]}")


BEAM_FPS = 7  # a beam frame is ~8 rect GETs + a batch (~140ms on the device)


def _beam(cv, seq, style, total, bg):
    """scanline: one head sweeping down. crt: a flash line mid-region, then
    two heads opening up and down. Content appears behind the head(s); the
    head is a white row with a dkteal afterglow trailing it."""
    x0, y0, x1, y1 = _bbox(seq)
    boxes = list(cv.boxes)
    rows = {}  # screen row -> dots covering it, to repaint after the beam passes
    for d in seq:
        for yy in range(d["y"], d["y"] + d.get("s", 1)):
            rows.setdefault(yy, []).append(d)
    cy = (y0 + y1) // 2
    if style == "crt":
        key = lambda d: abs(d["y"] + d.get("s", 1) / 2 - cy)
        span = max(cy - y0, y1 - cy)
        _hline(cv, cy, x0, x1, BEAM, boxes)  # the power-on flash
        time.sleep(min(0.4, total * 0.05))
    else:
        key = lambda d: d["y"] - y0
        span = y1 - y0
    pending = sorted(seq, key=key)
    frames = max(2, int(BEAM_FPS * total))
    shown, prev, i = set(), [], 0
    t0 = time.monotonic()
    for f in range(1, frames + 2):
        p = span * min(f, frames) / frames
        out = []
        while i < len(pending) and key(pending[i]) <= p:
            out.append(pending[i])
            shown.add(id(pending[i]))
            i += 1
        for y in prev:  # paint out last frame's beam rows...
            _hline(cv, y, x0, x1, bg(x0, y), boxes)
        # ...then the image under them, plus whatever the beam just uncovered
        cv.batch(out + [d for y in prev for d in rows.get(y, []) if id(d) in shown])
        if f > frames:
            break
        fronts = [y0 + int(p)] if style == "scanline" else [cy - int(p), cy + int(p)]
        prev = []
        for fy in fronts:
            trail = fy - 1 if style == "scanline" else (fy + 1 if fy < cy else fy - 1)
            for y, c in ((fy, BEAM), (trail, GLOW)):
                if y0 <= y < y1 and y not in prev:
                    _hline(cv, y, x0, x1, c, boxes)
                    prev.append(y)
        _sleep_until(t0 + total * f / frames)


def _glitch(cv, seq, total, bg, rng):
    """Bands of rows arrive torn: hotpink/cyan ghosts shoved sideways hold a
    beat, then the true band snaps in over the background. Now and then a
    settled band tears again (an aftershock) before the signal locks."""
    x0, y0, x1, y1 = _bbox(seq)
    boxes = list(cv.boxes)
    bands, y = [], y0
    while y < y1:
        h = rng.randint(3, 14)
        bands.append((y, min(y1, y + h)))
        y += h
    members = {b: [d for d in seq if b[0] <= d["y"] < b[1]] for b in bands}
    order = [b for b in bands if members[b]]
    rng.shuffle(order)
    settled = []

    def tear(band, hold):
        ds = members[band]
        dx = rng.choice((-1, 1)) * rng.randint(6, 28)
        ghosts = []
        for d in ds:
            for c, off in ((GHOSTS[0], dx), (GHOSTS[1], -dx // 2)):
                gx = d["x"] + off
                if 0 <= gx < 320 - d.get("s", 1) and not _behind(boxes, gx, d["y"], d.get("s", 1)):
                    ghosts.append({**d, "x": gx, "r": c[0], "g": c[1], "b": c[2]})
        cv.batch(ghosts)
        time.sleep(hold)
        erase = [{**g, "r": c[0], "g": c[1], "b": c[2]} for g in ghosts for c in [bg(g["x"], g["y"])]]
        near = [d for d in settled if band[0] - 8 <= d["y"] < band[1] + 8]  # ghosts crossed these
        cv.batch(erase + ds + near)

    per = total / max(len(order), 1)
    t0 = time.monotonic()
    for k, band in enumerate(order):
        tear(band, min(0.12, per * 0.5))
        settled += members[band]
        if settled and rng.random() < 0.15:  # aftershock
            tear(rng.choice(order[:k + 1]), 0.06)
        _sleep_until(t0 + per * (k + 1))


def _sleep_until(deadline):
    left = deadline - time.monotonic()
    if left > 0:
        time.sleep(left)
