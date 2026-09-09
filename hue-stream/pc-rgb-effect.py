#!/usr/bin/env python3
"""
pc-rgb-effect.py — persistent animated RGB effects on the Windows PC via OpenRGB.
Runs until killed. Vulpes palette, gamut-edge saturated so LEDs read vivid.

  pc-rgb-effect.py [wave|breathe|pulse] [--host 10.0.0.169] [--port 6742]
                   [--speed 0.9] [--fps 30]

Driven by `computah rgb wave` etc. Self-heals if OpenRGB drops.
"""
import argparse, math, sys, time
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

PINK = (255, 0, 60)
TEAL = (0, 230, 245)


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return RGBColor(int(a[0] + (b[0] - a[0]) * t),
                    int(a[1] + (b[1] - a[1]) * t),
                    int(a[2] + (b[2] - a[2]) * t))


def connect(host, port):
    c = OpenRGBClient(host, port, "imacpro-effect")
    time.sleep(0.6)
    mobo = next((d for d in c.devices if "DualSense" not in d.name), None)
    ds = next((d for d in c.devices if "DualSense" in d.name), None)
    if mobo:
        try: mobo.set_mode("Direct")
        except Exception: pass
        z = mobo.zones[2] if len(mobo.zones) > 2 else mobo.zones[-1]
        if len(z.leds) < 10:
            try: z.resize(60)
            except Exception: pass
            time.sleep(0.4)
    if ds:
        try: ds.set_mode("Direct")
        except Exception: pass
    return c, mobo, ds


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("effect", nargs="?", default="wave", choices=["wave", "breathe", "pulse"])
    ap.add_argument("--host", default="10.0.0.169")
    ap.add_argument("--port", type=int, default=6742)
    ap.add_argument("--speed", type=float, default=0.9)
    ap.add_argument("--fps", type=float, default=30)
    args = ap.parse_args()

    period = 1.0 / args.fps
    c = mobo = ds = None
    t0 = time.time()
    print(f"[pc-rgb-effect] {args.effect} -> {args.host}:{args.port}", flush=True)

    while True:
        t1 = time.time()
        try:
            if c is None:
                c, mobo, ds = connect(args.host, args.port)
                z = mobo.zones[2] if (mobo and len(mobo.zones) > 2) else (mobo.zones[-1] if mobo else None)
                n = len(z.leds) if z else 0
                print(f"[pc-rgb-effect] connected: {n} strip leds", flush=True)

            t = (time.time() - t0) * args.speed
            if mobo and n:
                leds = []
                for i in range(n):
                    if args.effect == "wave":
                        w = 0.5 + 0.5 * math.sin(t + i * 0.35)
                    elif args.effect == "breathe":
                        w = 0.5 + 0.5 * math.sin(t)          # whole strip together
                    else:  # pulse — sharp comet
                        w = max(0.0, 1.0 - ((i - (t * 6) % n) % n) / n) ** 3
                    leds.append(mix(PINK, TEAL, w))
                z.set_colors(leds, fast=True)
            if ds:
                w = 0.5 + 0.5 * math.sin(t)
                ds.set_color(mix(PINK, TEAL, w), fast=True)

        except Exception as e:
            print(f"[pc-rgb-effect] lost connection ({e}); retrying in 3s", flush=True)
            c = None
            time.sleep(3)
            continue

        dt = time.time() - t1
        if dt < period:
            time.sleep(period - dt)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
