#!/usr/bin/env python3
"""
pc-rgb-effect.py — persistent animated RGB effects on the Windows PC via OpenRGB.
Runs until killed. Vulpes palette, gamut-edge saturated so LEDs read vivid.

  pc-rgb-effect.py [wave|breathe|pulse] [--host 10.0.0.169] [--port 6742]
                   [--speed 0.9] [--fps 30]

Driven by `computah rgb wave` etc. Self-heals if OpenRGB drops.

Desk sync: every other frame the strip's colors are also published to the
local hue-stream daemon (UDP 127.0.0.1:9999) as {type:'screen', zones:[...]}
— if the daemon is up in `screen` ambient, the Hue desk lights render the
same wave. Skipped while screen-sync.py runs (the iMac screen wins).

Event flashes: rgb-flash signals via /tmp/pc-rgb-flash ("R G B", mtime =
trigger); the engine overrides all LEDs with that color for ~0.45s so
desk-event pulses stay visible while an effect is running.
"""
import argparse, json, math, os, socket, subprocess, sys, time
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

PINK = (255, 0, 60)
TEAL = (0, 230, 245)
DAEMON = ("127.0.0.1", 9999)
FLASH_FILE = "/tmp/pc-rgb-flash"
FLASH_HOLD = 0.45
ZONES = 5


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


def flash_override():
    """Return (r,g,b) if a recent rgb-flash signal should override, else None."""
    try:
        st = os.stat(FLASH_FILE)
        if time.time() - st.st_mtime < FLASH_HOLD:
            with open(FLASH_FILE) as f:
                r, g, b = (int(v) for v in f.read().split()[:3])
            return (r, g, b)
    except Exception:
        pass
    return None


def screensync_running():
    try:
        return subprocess.run(["pgrep", "-f", "screen-sync.py"],
                              capture_output=True).returncode == 0
    except Exception:
        return False


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
    n = 0
    t0 = time.time()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    frame = 0
    hue_ok = True      # suppressed while screen-sync.py owns the zones
    hue_check = 0.0
    print(f"[pc-rgb-effect] {args.effect} -> {args.host}:{args.port} (+hue zones)", flush=True)

    while True:
        t1 = time.time()
        try:
            if c is None:
                c, mobo, ds = connect(args.host, args.port)
                z = mobo.zones[2] if (mobo and len(mobo.zones) > 2) else (mobo.zones[-1] if mobo else None)
                n = len(z.leds) if z else 0
                print(f"[pc-rgb-effect] connected: {n} strip leds", flush=True)

            t = (time.time() - t0) * args.speed
            fo = flash_override()
            leds = []
            if mobo and n:
                for i in range(n):
                    if fo:
                        leds.append(RGBColor(*fo))
                        continue
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
                ds.set_color(RGBColor(*fo) if fo else mix(PINK, TEAL, w), fast=True)

            # Desk sync: publish strip colors as screen zones (0-1 floats).
            # ~15Hz is plenty — the daemon eases toward targets at 50Hz.
            frame += 1
            if frame % 2 == 0 and leds:
                if time.time() - hue_check > 5:
                    hue_ok = not screensync_running()
                    hue_check = time.time()
                if hue_ok:
                    zones = []
                    step = max(1, len(leds) // ZONES)
                    for zi in range(ZONES):
                        led = leds[min(zi * step + step // 2, len(leds) - 1)]
                        zones.append([round(led.red / 255, 3),
                                      round(led.green / 255, 3),
                                      round(led.blue / 255, 3)])
                    try:
                        sock.sendto(json.dumps({"type": "screen", "zones": zones}).encode(), DAEMON)
                    except OSError:
                        pass

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
