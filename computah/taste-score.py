"""EJ-taste scorer for the muse gallery — runs ON computah (shipped by
muse-taste-backfill). One CSV row per render: its EJ-taste score (z-scaled
against EJ's photo corpus) + the knobs that made it + whether EJ starred it.

Resumable (skips ids already in the CSV), IDLE CPU priority, and it stops
itself the moment a game/anti-cheat process appears — never lags a match.
"""
import csv, ctypes, json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from taste import metrics  # shipped copy of ~/roadtrip-rank/taste.py

GALLERY = os.environ.get("MUSE_GALLERY", r"C:\dev\computah\renders\muse-gallery")
FAVS = os.environ.get("MUSE_FAVS", r"C:\dev\computah\renders\favorites")
OUT = os.environ.get("MUSE_SCORES", os.path.join(HERE, "render-scores.csv"))
GAME = ("fortniteclient", "easyanticheat", "beservice", "battleye")
FIELDS = ["id", "ejtaste", "c", "t", "sy", "sgce", "favorite", "init_source", "style",
          "sampler", "size", "steps", "strength", "cfg", "team", "prompt_from", "ts"]

def gaming():
    try:
        out = subprocess.run(["tasklist", "/fo", "csv", "/nh"], capture_output=True, text=True).stdout.lower()
    except FileNotFoundError:  # not Windows (local test run)
        return False
    return any(g in out for g in GAME)

def main():
    try:
        ctypes.windll.kernel32.SetPriorityClass(ctypes.windll.kernel32.GetCurrentProcess(), 0x40)  # IDLE
    except Exception:
        pass
    st = json.load(open(os.path.join(HERE, "corpus-stats.json")))
    done = set()
    if os.path.exists(OUT) and os.path.getsize(OUT) == 0:
        os.remove(OUT)  # an aborted run can leave an empty file with no header
    if os.path.exists(OUT):
        done = {r["id"] for r in csv.DictReader(open(OUT, newline="", encoding="utf-8"))}
    favs = {f[5:-4] for f in os.listdir(FAVS) if f.startswith("muse-") and f.endswith(".png")} if os.path.isdir(FAVS) else set()
    todo = sorted(f[5:-4] for f in os.listdir(GALLERY)
                  if f.startswith("muse-") and f.endswith(".png") and not f.endswith("-init.png"))
    todo = [i for i in todo if i not in done]
    new = not os.path.exists(OUT)
    w = csv.DictWriter(open(OUT, "a", newline="", encoding="utf-8"), fieldnames=FIELDS)
    if new:
        w.writeheader()
    n = 0
    for i, rid in enumerate(todo):
        if i % 100 == 0 and gaming():
            print(f"game detected — stopping after {n} (resumable)", flush=True)
            return 3
        try:
            c, t, sy, sg, ce = metrics(os.path.join(GALLERY, f"muse-{rid}.png"))
        except Exception as e:
            print(f"skip {rid}: {e}", flush=True)
            continue
        me = {"c": c, "t": t, "sy": sy, "sgce": sg * ce}
        z = sum(st["w"][k] * (me[k] - st["mu"][k]) / st["sd"][k] for k in me)
        tr = {}
        try:
            tr = json.load(open(os.path.join(GALLERY, f"muse-{rid}.json"), encoding="utf-8"))
        except Exception:
            pass
        bs = tr.get("batch_source") or ""
        w.writerow({"id": rid, "ejtaste": round(z, 3), "c": round(c, 4), "t": round(t, 4),
                    "sy": round(sy, 4), "sgce": round(sg * ce, 4),
                    "favorite": int(rid in favs), "init_source": tr.get("init_source", ""),
                    "style": tr.get("style") or "", "sampler": tr.get("sampler", ""),
                    "size": tr.get("size", ""), "steps": tr.get("steps", ""),
                    "strength": tr.get("img2img_strength", ""), "cfg": tr.get("cfg", ""),
                    "team": bs[5:bs.index(" ·")] if bs.startswith("team ") and " ·" in bs else "",
                    "prompt_from": tr.get("prompt_from", ""), "ts": tr.get("ts", "")})
        n += 1
        if n % 500 == 0:
            print(f"scored {n}/{len(todo)}", flush=True)
    print(f"done — scored {n} new, {len(done) + n} total", flush=True)
    return 0

if __name__ == "__main__":
    sys.exit(main())
