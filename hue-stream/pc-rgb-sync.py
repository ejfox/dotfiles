#!/usr/bin/env python3
"""
pc-rgb-sync.py — sample the iMac's primary display and drive the Windows PC's
RGB (OpenRGB over the network) so the PC case breathes with the Mac screen,
same feed spirit as screen-sync.py (which drives the Hue lights).

Maps left->right screen color bands across the motherboard's Aura Addressable
header, and sets the DualSense lightbar to the overall dominant color.

  pc-rgb-sync.py [--host 10.0.0.169] [--port 6742] [--fps 20]
                 [--sat 1.5] [--gamma 0.85] [--floor 0.03] [--ease 0.25]

Run via `computah rgb on`. Needs macOS Screen Recording permission for the
terminal app. Reconnects if OpenRGB drops.
"""
import argparse, sys, time
import numpy as np
import mss
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor


def pick_display(sct):
    mons = sct.monitors  # [0]=all, [1..]=physical
    best, best_area = None, -1
    for m in mons[1:]:
        if m["width"] <= m["height"]:
            continue  # skip portrait
        area = m["width"] * m["height"]
        if area > best_area:
            best, best_area = m, area
    return best or mons[1]


def saturate(col, white_cut, gamma, sat_boost):
    """Pull a color toward the gamut edge: remove shared white (min channel),
    so RGB LEDs render vivid instead of washed-out."""
    m = col.min()
    col = col - white_cut * m               # kill the grey/white component
    col = np.clip(col, 0, None)
    peak = col.max()
    if peak > 1e-4:
        col = col / peak * min(1.0, (m + peak))  # renormalize, keep brightness
    col = np.clip(col * sat_boost, 0, 1) ** gamma
    return col


def sample_zones(sct, mon, n, sat_boost, gamma, floor, white_cut):
    shot = sct.grab(mon)
    arr = np.asarray(shot)[:, :, :3].astype(np.float32) / 255.0  # BGRA->BGR
    arr = arr[:, :, ::-1]  # -> RGB
    h, w, _ = arr.shape
    # heavy downsample for speed + blur
    step_y = max(1, h // 120)
    arr = arr[::step_y]
    zones = []
    for i in range(n):
        x0 = int(w * i / n)
        x1 = int(w * (i + 1) / n)
        band = arr[:, x0:x1, :].reshape(-1, 3)
        # saturation-weighted average so a vivid minority beats grey majority
        mx = band.max(axis=1)
        mn = band.min(axis=1)
        sat = (mx - mn) / (mx + 1e-6)
        wts = (sat ** 1.5) + 0.02
        col = (band * wts[:, None]).sum(axis=0) / wts.sum()
        col = saturate(col, white_cut, gamma, sat_boost)
        if col.max() < floor:
            col[:] = floor
        zones.append(col)
    return zones


def to_rgbcolor(c):
    return RGBColor(int(c[0] * 255), int(c[1] * 255), int(c[2] * 255))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="10.0.0.169")
    ap.add_argument("--port", type=int, default=6742)
    ap.add_argument("--fps", type=float, default=20)
    ap.add_argument("--sat", type=float, default=1.6)
    ap.add_argument("--gamma", type=float, default=0.8)
    ap.add_argument("--floor", type=float, default=0.03)
    ap.add_argument("--ease", type=float, default=0.25)
    ap.add_argument("--white-cut", type=float, default=0.75,
                    help="0-1: fraction of the shared white/min channel to remove so LEDs read vivid, not washed out")
    args = ap.parse_args()

    period = 1.0 / args.fps
    client = None
    mobo = ds = None
    strip_n = 0
    eased = None

    with mss.mss() as sct:
        mon = pick_display(sct)
        print(f"[pc-rgb-sync] display {mon['width']}x{mon['height']} -> {args.host}:{args.port}", flush=True)
        while True:
            t0 = time.time()
            try:
                if client is None:
                    client = OpenRGBClient(args.host, args.port, "imacpro-desksync")
                    time.sleep(0.5)
                    mobo = next((d for d in client.devices if "DualSense" not in d.name), None)
                    ds = next((d for d in client.devices if "DualSense" in d.name), None)
                    if mobo:
                        try: mobo.set_mode("Direct")
                        except Exception: pass
                        strip = mobo.zones[2] if len(mobo.zones) > 2 else mobo.zones[-1]
                        # OpenRGB forgets zone sizes on restart — re-assert so we always have LEDs to drive
                        if len(strip.leds) < 10:
                            try: strip.resize(60)
                            except Exception: pass
                            time.sleep(0.4)
                        strip_n = len(strip.leds)
                    print(f"[pc-rgb-sync] connected: strip={strip_n} leds, dualsense={'yes' if ds else 'no'}", flush=True)
                    eased = None

                nz = max(3, min(8, strip_n // 8)) if strip_n else 5
                zones = sample_zones(sct, mon, nz, args.sat, args.gamma, args.floor, args.white_cut)
                if eased is None:
                    eased = [z.copy() for z in zones]
                else:
                    for i in range(nz):
                        eased[i] += (zones[i] - eased[i]) * args.ease

                if mobo and strip_n:
                    strip = mobo.zones[2] if len(mobo.zones) > 2 else mobo.zones[-1]
                    leds = []
                    for j in range(strip_n):
                        zi = min(nz - 1, int(j * nz / strip_n))
                        leds.append(to_rgbcolor(eased[zi]))
                    strip.set_colors(leds, fast=True)
                if ds:
                    dom = np.mean(eased, axis=0)
                    ds.set_color(to_rgbcolor(dom), fast=True)

            except Exception as e:
                print(f"[pc-rgb-sync] lost connection ({e}); retrying in 3s", flush=True)
                client = None
                time.sleep(3)
                continue

            dt = time.time() - t0
            if dt < period:
                time.sleep(period - dt)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
