#!/usr/bin/env python3
"""Measure end-to-end latency: UDP pulse → bulb visible change via webcam.

Usage:
    # In one terminal:
    hue-stream daemon dark
    # In another:
    hue-latency [n]

The daemon must be in `dark` mode so bulbs are black between pulses. Each
trial fires a bright white pulse (huge radius — hits every bulb) and times
from UDP-send until the webcam sees the scene brighten.
"""
import argparse
import json
import os
import socket
import statistics
import sys
import time

import cv2
import numpy as np

DAEMON = ('127.0.0.1', 9999)
MIN_DELTA = 15   # average frame brightness must rise this much above dark baseline


def fire_pulse(sock):
    msg = json.dumps({
        'type': 'pulse',
        'position': [0, 0, 0],
        'color': [1, 1, 1],
        'duration': 0.5,
        'radius': 10,  # guarantees every bulb is at full falloff
    })
    t = time.perf_counter()
    sock.sendto(msg.encode(), DAEMON)
    return t


def open_webcam():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        sys.exit('error: could not open webcam')
    cap.set(cv2.CAP_PROP_FPS, 60)
    for _ in range(30):
        cap.read()  # warm-up
    return cap


def measure_trial(cap, sock, baseline_sec=0.4, timeout=1.0):
    # Baseline: average frame brightness while scene is dark
    samples = []
    t0 = time.perf_counter()
    while time.perf_counter() - t0 < baseline_sec:
        ret, frame = cap.read()
        if ret:
            samples.append(float(frame.mean()))
    if len(samples) < 10:
        return None, 'not enough baseline frames'
    base = np.mean(samples)

    t_send = fire_pulse(sock)
    t_start = time.perf_counter()
    peak = 0.0
    while time.perf_counter() - t_start < timeout:
        ret, frame = cap.read()
        if not ret:
            continue
        t_frame = time.perf_counter()
        delta = float(frame.mean()) - base
        if delta > peak:
            peak = delta
        if delta > MIN_DELTA:
            return (t_frame - t_send) * 1000, None
    return None, f'pulse not detected (peak Δ={peak:+.1f}, needed {MIN_DELTA})'


def ascii_hist(values, bin_ms=10, width=30):
    lo = int(min(values) // bin_ms) * bin_ms
    hi = int(max(values) // bin_ms + 1) * bin_ms
    counts = [0] * ((hi - lo) // bin_ms + 1)
    for v in values:
        counts[int((v - lo) // bin_ms)] += 1
    peak = max(counts)
    for i, c in enumerate(counts):
        bar = '█' * int(c / peak * width) if peak else ''
        print(f'  {lo + i * bin_ms:3d}–{lo + (i + 1) * bin_ms:<3d}ms  {bar} {c}' if c else '')


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('n', nargs='?', type=int, default=20)
    args = p.parse_args()

    # Quick sanity-check that the daemon is alive
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    print('assuming `hue-stream daemon dark` is running.')
    cap = open_webcam()
    print(f'running {args.n} trials...\n')

    latencies = []
    for i in range(args.n):
        time.sleep(1.0)
        for _ in range(3):
            cap.read()  # drain stale frames
        ms, err = measure_trial(cap, sock)
        if ms is None:
            print(f'  [{i + 1:2}] skip — {err}')
        else:
            latencies.append(ms)
            print(f'  [{i + 1:2}] {ms:5.1f} ms')
    cap.release()

    if not latencies:
        sys.exit('\nno samples. is the daemon running in `dark` mode?')

    print(f'\n{len(latencies)}/{args.n} samples')
    print(f'median  {statistics.median(latencies):5.1f} ms')
    print(f'mean    {statistics.mean(latencies):5.1f} ms')
    print(f'min     {min(latencies):5.1f} ms')
    print(f'max     {max(latencies):5.1f} ms')
    if len(latencies) > 1:
        print(f'stddev  {statistics.stdev(latencies):5.1f} ms')
    print()
    ascii_hist(latencies)


if __name__ == '__main__':
    main()
