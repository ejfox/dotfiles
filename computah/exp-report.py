#!/usr/local/bin/python3
"""exp-report — what did the FLUX steering experiment arms do to EJ's taste signals?

Joins every steered wall cell (arms logged by bin/muse-steer) with the taste events
(★ favorites, ▽ downs, pair picks, inspect clicks, why-notes) and prints, per arm
level: cells, ★/▽/inspect rates with 95% Wilson CIs, pair win rate, extra GPU time,
plus a power note (cells per arm needed to detect a 2x ★-rate difference).

  computah/exp-report.py                 Mac: arms from ~/.cache/muse/steer.jsonl,
                                         labels pulled live from computah :7861
  computah/exp-report.py --traces DIR    arms from muse-*.json traces in DIR instead
                                         (e.g. a copy of renders\\muse-gallery)
  options: --since YYYY-MM-DD  --all (count unseen cells too; default = SEEN cells
           only, via muse_presence, when usage logs exist)  --json (machine output)
           --host IP

Factors (independent per cell, see muse-steer):
  ref 0|1|2 · bestof 1|N (pick judge|random) · particles 1|K (pick judge|random)
A factor is compared only among cells where it was ELIGIBLE (cheap enough to run),
so the cost gate can't confound it. "judge vs random" pools best-of and particle
cells: the difference is the value of the (unvalidated) scorer at equal compute.
"""
import glob, json, math, os, sys, urllib.request
from collections import defaultdict

ARGS = sys.argv[1:]


def arg(flag, default=None):
    return ARGS[ARGS.index(flag) + 1] if flag in ARGS and ARGS.index(flag) + 1 < len(ARGS) else default


HOSTS = [arg("--host")] if arg("--host") else ["10.0.0.169", "100.106.221.70"]


def fetch(path):
    for h in HOSTS:
        try:
            return urllib.request.urlopen(f"http://{h}:7861/{path}", timeout=10).read()
        except Exception:
            continue
    raise SystemExit(f"can't reach computah :7861 for /{path} (try --host)")


def wilson(k, n, z=1.96):
    if n == 0:
        return (float("nan"),) * 3
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    m = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return p, max(0.0, c - m), min(1.0, c + m)


def n_for_2x(p1, alpha_z=1.96, power_z=0.8416):
    """cells PER ARM for a two-sided two-proportion test to detect p2 = 2*p1"""
    p2 = min(0.99, 2 * p1)
    pb = (p1 + p2) / 2
    num = (alpha_z * math.sqrt(2 * pb * (1 - pb)) + power_z * math.sqrt(p1 * (1 - p1) + p2 * (1 - p2))) ** 2
    return math.ceil(num / (p2 - p1) ** 2)


def load_arms():
    cells = {}
    tdir = arg("--traces")
    if tdir:
        for f in glob.glob(os.path.join(tdir, "muse-*.json")):
            try:
                t = json.load(open(f))
            except Exception:
                continue
            if isinstance(t.get("arms"), dict):
                cells[t["id"]] = {"id": t["id"], "ts": t.get("ts"), "arms": t["arms"], "src": t.get("init_source")}
    else:
        p = arg("--arms") or os.path.expanduser("~/.cache/muse/steer.jsonl")
        for line in open(p) if os.path.exists(p) else []:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if r.get("id") and isinstance(r.get("arms"), dict) and not r["id"].startswith("bench"):
                cells[r["id"]] = {"id": r["id"], "ts": r.get("ts"), "arms": r["arms"]}
    since = arg("--since")
    if since:
        cells = {k: v for k, v in cells.items() if (v.get("ts") or "") >= since}
    return cells


def load_labels():
    stars = set(json.loads(fetch("favlist")).get("ids") or [])
    down, insp, why = {}, defaultdict(int), defaultdict(int)
    wins, losses = defaultdict(int), defaultdict(int)
    for line in fetch("taste/events.jsonl").decode("utf-8", "replace").splitlines():
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if e.get("kind") == "studio" or e.get("win_kind") == "studio" and e.get("lose_kind") == "studio":
            continue
        t = e.get("type")
        if t == "down":
            down[e.get("id")] = bool(e.get("on", True))      # latest state wins
        elif t == "inspect":
            insp[e.get("id")] += 1
        elif t == "pair":
            if e.get("win_kind", "flux") == "flux":
                wins[e.get("win")] += 1
            if e.get("lose_kind", "flux") == "flux":
                losses[e.get("lose")] += 1
        elif t == "why":
            why[e.get("id")] += 1
    return stars, {k for k, v in down.items() if v}, insp, wins, losses, why


def levels(c):
    a = c["arms"]
    out = {}
    if a.get("ref_eligible", True):
        out["ref"] = str(a.get("ref", 0))
    if a.get("bestof_eligible", True):
        out["bestof"] = "1" if a.get("bestof", 1) <= 1 else f"{a['bestof']}"
        if a.get("bestof", 1) > 1 and a.get("bestof_detail", {}).get("n_done", 0) >= 2:
            out["bestof_pick"] = a.get("bestof_pick")
    if a.get("particles_eligible", True):
        pd = a.get("particle_detail") or {}
        ran = a.get("particles", 1) > 1 and "winner" in pd
        out["particles"] = f"{a['particles']}" if ran else ("1" if a.get("particles", 1) <= 1 else "aborted")
        if ran:
            out["particle_pick"] = a.get("particle_pick")
    picks = [p for p in (out.get("bestof_pick"), out.get("particle_pick")) if p]
    if picks:
        out["any_pick"] = "judge" if "judge" in picks and "random" not in picks else ("random" if "judge" not in picks else "mixed")
    out["scorer"] = a.get("scorer") or "-"
    return out


def main():
    cells = load_arms()
    if not cells:
        print("no steered cells yet (arms log ~/.cache/muse/steer.jsonl is empty) — let the wall run")
        return
    stars, downs, insp, wins, losses, why = load_labels()
    seen_mode = "--all" not in ARGS
    if seen_mode:
        try:
            sys.path.insert(0, os.path.expanduser("~/.dotfiles/bin"))
            import muse_presence as MP
            flags = MP.seen_flags(list(cells.values()))
            kept = {k: v for k, v in cells.items() if flags.get(k) or k in stars}
            note = f"SEEN cells only: {len(kept)} of {len(cells)} (presence; ★ always counts as seen; --all to include unseen)"
            cells = kept
        except Exception as e:
            note = f"presence unavailable ({e}); counting ALL cells"
    else:
        note = f"ALL {len(cells)} cells (unseen included)"
    rows = defaultdict(lambda: defaultdict(lambda: {"n": 0, "star": 0, "down": 0, "insp": 0, "why": 0, "pw": 0, "pl": 0, "t": []}))
    for cid, c in cells.items():
        for fac, lev in levels(c).items():
            r = rows[fac][lev]
            r["n"] += 1
            r["star"] += cid in stars
            r["down"] += cid in downs
            r["insp"] += insp.get(cid, 0) > 0
            r["why"] += why.get(cid, 0) > 0
            r["pw"] += wins.get(cid, 0)
            r["pl"] += losses.get(cid, 0)
            r["t"].append(float(c["arms"].get("extra_s") or 0))
    tot = len(cells)
    base = sum(1 for c in cells if c in stars) / tot if tot else 0
    if "--json" in ARGS:
        print(json.dumps({f: {l: {k: v for k, v in r.items() if k != "t"} | {"extra_s_mean": sum(r["t"]) / len(r["t"]) if r["t"] else 0}
                              for l, r in levs.items()} for f, levs in rows.items()}, indent=1))
        return
    print(f"◆ STEERING EXPERIMENTS — {tot} cells · {note}")
    print(f"  ★ base rate {base:.3%}  · labels: {len(stars)} ★ total, {len(downs)} ▽, "
          f"{sum(insp.values())} inspects, {sum(wins.values())} pair picks")
    hdr = f"  {'level':<10}{'cells':>6}  {'★ rate [95% CI]':<24}{'▽ rate':>8}{'inspect':>9}{'pair W-L':>10}{'+GPU s':>8}"
    order = ["ref", "bestof", "bestof_pick", "particles", "particle_pick", "any_pick", "scorer"]
    titles = {"ref": "REF images (0 = control)", "bestof": "BEST-OF-N (1 = control)",
              "bestof_pick": "best-of pick (random = same-compute control)", "particles": "PARTICLES (1 = control)",
              "particle_pick": "particle pick (random = control)", "any_pick": "JUDGE vs RANDOM (pooled best-of + particles)",
              "scorer": "scorer used"}
    for fac in order:
        if fac not in rows:
            continue
        print(f"\n○ {titles[fac]}")
        print(hdr)
        for lev in sorted(rows[fac]):
            r = rows[fac][lev]
            p, lo, hi = wilson(r["star"], r["n"])
            ci = f"{r['star']}/{r['n']} {p:.1%} [{lo:.1%}–{hi:.1%}]"
            t = sum(r["t"]) / len(r["t"]) if r["t"] else 0
            print(f"  {lev:<10}{r['n']:>6}  {ci:<24}{r['down'] / r['n']:>8.1%}{r['insp'] / r['n']:>9.1%}"
                  f"{r['pw']:>5}-{r['pl']:<4}{t:>8.1f}")
    p1 = base if base > 0 else 0.02
    need = n_for_2x(p1)
    smallest = min((r["n"] for f, levs in rows.items() if f != "scorer"
                    for l, r in levs.items() if l not in ("mixed", "aborted")), default=0)
    print(f"\n◇ POWER: at a {p1:.2%} ★ base rate{' (prior; no stars yet)' if base == 0 else ''}, detecting a 2x ★-rate "
          f"difference (α=.05, 80% power) needs ~{need} cells PER ARM LEVEL; the smallest level has {smallest} "
          f"→ ~{max(0, need - smallest)} more. Inspect/▽ rates are denser signals and resolve sooner.")
    print("◇ Read judge-vs-random first: if judge ≈ random, best-of/particles only buy variance, not taste.")


if __name__ == "__main__":
    main()
