#!/usr/bin/env python3
"""
screen-sync.py — sample the primary display's dominant colors and stream them
to the hue-stream daemon (UDP 127.0.0.1:9999) as left→right color bands.

The daemon does the easing/HCL blending; this just extracts vivid "primary"
colors per horizontal zone and fires them ~24x/sec. Gaussian-ish blur comes
from heavy downsampling; grey-mush is avoided with saturation-weighted
averaging so a mostly-blue frame drives the lights blue, not toward grey.

  screen-sync.py [--zones 5] [--fps 24] [--sat 1.6] [--gamma 0.85]
                 [--floor 0.04] [--display auto|N] [--once]

Needs macOS Screen Recording permission for the terminal app running it.
"""
import argparse, json, socket, sys, time
import numpy as np
import mss

DAEMON = ("127.0.0.1", 9999)


def pick_display(sct, want):
    mons = sct.monitors  # [0]=all-combined, [1..]=each physical
    if want != "auto":
        idx = int(want)
        return mons[idx], idx
    # iMac Pro = the main 5K landscape panel: widest landscape by area.
    best, best_i, best_area = None, None, -1
    for i, m in enumerate(mons[1:], start=1):
        if m["width"] <= m["height"]:
            continue  # skip portrait (the rotated monitor)
        area = m["width"] * m["height"]
        if area > best_area:
            best, best_i, best_area = m, i, area
    if best is None:  # no landscape found; fall back to monitor 1
        return mons[1], 1
    return best, best_i


def primary_color(block, sat_boost, gamma, floor):
    """Saturation-weighted vivid color from an HxWx3 uint8 RGB block."""
    a = block.astype(np.float32) / 255.0
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    sat = (mx - mn) / (mx + 1e-6)
    val = mx
    w = (sat * sat) * val + 1e-4          # favor vivid, bright pixels
    wsum = w.sum()
    if wsum < 1e-6:
        return [0.0, 0.0, 0.0]
    col = np.array([(r * w).sum(), (g * w).sum(), (b * w).sum()]) / wsum
    # push chroma around luma so the band reads as a color, not a wash
    luma = 0.2126 * col[0] + 0.7152 * col[1] + 0.0722 * col[2]
    col = luma + (col - luma) * sat_boost
    col = np.clip(col, 0.0, 1.0) ** gamma
    # keep a faint floor so dark scenes glow rather than switch off
    col = floor + col * (1.0 - floor)
    return [float(col[0]), float(col[1]), float(col[2])]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--zones", type=int, default=5)
    ap.add_argument("--fps", type=float, default=24.0)
    ap.add_argument("--sat", type=float, default=1.6, help="saturation boost")
    ap.add_argument("--gamma", type=float, default=0.85, help="<1 brightens mids")
    ap.add_argument("--floor", type=float, default=0.04, help="min brightness 0..1")
    ap.add_argument("--display", default="auto", help="'auto' or monitor index")
    ap.add_argument("--once", action="store_true", help="print one frame and exit")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    period = 1.0 / max(1.0, args.fps)
    # downsample target per grab (gaussian-ish blur); wide enough to split zones
    DS_W, DS_H = max(args.zones * 16, 96), 32

    with mss.mss() as sct:
        mon, idx = pick_display(sct, args.display)
        if not args.quiet:
            print(f"[screen-sync] display {idx}: {mon['width']}x{mon['height']} "
                  f"@ ({mon['left']},{mon['top']})  zones={args.zones} fps={args.fps:g}",
                  file=sys.stderr)
        # PIL for a cheap high-quality downscale (acts as the blur)
        from PIL import Image
        while True:
            t0 = time.time()
            raw = sct.grab(mon)                      # BGRA
            img = Image.frombytes("RGB", raw.size, raw.rgb)
            small = img.resize((DS_W, DS_H), Image.BILINEAR)
            arr = np.asarray(small)                  # DS_H x DS_W x 3
            zones = []
            zw = DS_W // args.zones
            for z in range(args.zones):
                x0 = z * zw
                x1 = DS_W if z == args.zones - 1 else (z + 1) * zw
                zones.append(primary_color(arr[:, x0:x1, :], args.sat, args.gamma, args.floor))
            sock.sendto(json.dumps({"type": "screen", "zones": zones}).encode(), DAEMON)
            if args.once:
                print(json.dumps({"display": idx, "zones": [[round(c, 3) for c in z] for z in zones]}))
                return
            dt = time.time() - t0
            if dt < period:
                time.sleep(period - dt)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
