"""taste-export — EJ's labeled wall renders in a LoRA / DPO-ready layout. Runs ON computah.

Nothing trains here. This just keeps the labeled data in the shape the trainers want,
so a personal LoRA (positives) or a Diffusion-DPO / Flow-GRPO run (preference pairs) can
start the day there's enough signal (hundreds of labels; today there are dozens).

  venv\\Scripts\\python.exe taste-export.py [OUT_DIR]
      default OUT_DIR = C:\\Users\\ejfox\\farm\\taste\\export\\<YYYYMMDD>

  OUT_DIR\\
    lora\\<id>.png + <id>.txt     every ★ FLUX render + its prompt (kohya / ai-toolkit
                                  caption-sidecar layout); studio ★ go to lora_studio\\
    dpo\\pairs.jsonl              {prompt, chosen, rejected, kind, same_prompt, ...}
                                  kind = pair (EJ picked one of two) | star_vs_down
    dpo\\images\\<id>.png          every image a pair references
    labels.csv                    id, label, prompt, init_source, steering arms, ...
    manifest.json                 counts + what each trainer still needs

Sources: renders\\favorites (★), renders\\muse-gallery (renders + traces),
farm\\sd\\taste\\events.jsonl (▽ down, pair, inspect, why). Source:
~/.dotfiles/computah/taste-export.py (scp to C:\\Users\\ejfox\\farm\\taste\\).
"""
import csv, datetime, glob, json, os, shutil, sys

GALLERY = r"C:\dev\computah\renders\muse-gallery"
FAVS = r"C:\dev\computah\renders\favorites"
STUDIO_FAVS = os.path.join(FAVS, "studio")
EVENTS = r"C:\dev\computah\farm\sd\taste\events.jsonl"
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    r"C:\Users\ejfox\farm\taste\export", datetime.date.today().strftime("%Y%m%d"))


def trace(rid):
    for d in (FAVS, GALLERY):
        p = os.path.join(d, f"muse-{rid}.json")
        if os.path.exists(p):
            try:
                return json.load(open(p, encoding="utf-8"))
            except Exception:
                pass
    return {}


def image(rid):
    for d in (FAVS, GALLERY):
        p = os.path.join(d, f"muse-{rid}.png")
        if os.path.exists(p):
            return p
    return None


def main():
    os.makedirs(os.path.join(OUT, "lora"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "lora_studio"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "dpo", "images"), exist_ok=True)
    stars = sorted(os.path.basename(f)[5:-4] for f in glob.glob(os.path.join(FAVS, "muse-*.png")))
    down, insp, pairs, why = {}, {}, [], {}
    for line in open(EVENTS, encoding="utf-8") if os.path.exists(EVENTS) else []:
        try:
            e = json.loads(line)
        except ValueError:
            continue
        t = e.get("type")
        if t == "down" and e.get("kind", "flux") == "flux":
            down[e.get("id")] = bool(e.get("on", True))
        elif t == "inspect" and e.get("kind", "flux") == "flux":
            insp[e.get("id")] = insp.get(e.get("id"), 0) + 1
        elif t == "pair":
            pairs.append(e)
        elif t == "why":
            why.setdefault(e.get("id"), []).append({"verdict": e.get("verdict"), "text": e.get("text")})
    downs = sorted(k for k, v in down.items() if v and k)

    # ── LoRA: positives + captions ──
    n_lora = 0
    for rid in stars:
        src = image(rid)
        if not src:
            continue
        shutil.copyfile(src, os.path.join(OUT, "lora", f"{rid}.png"))
        cap = trace(rid).get("prompt_full") or trace(rid).get("prompt_subject") or ""
        open(os.path.join(OUT, "lora", f"{rid}.txt"), "w", encoding="utf-8").write(cap)
        n_lora += 1
    n_studio = 0
    for f in glob.glob(os.path.join(STUDIO_FAVS, "*.png")):
        shutil.copyfile(f, os.path.join(OUT, "lora_studio", os.path.basename(f)))
        n_studio += 1

    # ── DPO pairs ──
    rows = []

    def add(win, lose, kind, extra=None):
        wp, lp = image(win), image(lose)
        if not (wp and lp):
            return
        tw, tl = trace(win), trace(lose)
        for rid, p in ((win, wp), (lose, lp)):
            dst = os.path.join(OUT, "dpo", "images", f"{rid}.png")
            if not os.path.exists(dst):
                shutil.copyfile(p, dst)
        pw, pl = tw.get("prompt_full") or "", tl.get("prompt_full") or ""
        r = {"prompt": pw, "chosen": f"images/{win}.png", "rejected": f"images/{lose}.png",
             "rejected_prompt": pl, "same_prompt": pw == pl and bool(pw), "kind": kind,
             "chosen_id": win, "rejected_id": lose,
             "chosen_arms": tw.get("arms"), "rejected_arms": tl.get("arms")}
        r.update(extra or {})
        rows.append(r)

    for e in pairs:
        if e.get("win_kind", "flux") == "flux" and e.get("lose_kind", "flux") == "flux":
            add(e.get("win"), e.get("lose"), "pair", {"ts": e.get("ts"), "ms": e.get("ms")})
    for s in stars:            # every ★ beats every ▽ (weak, cross-prompt; flagged)
        for d in downs:
            add(s, d, "star_vs_down")
    with open(os.path.join(OUT, "dpo", "pairs.jsonl"), "w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")

    # ── labels.csv ──
    ids = set(stars) | set(downs) | set(insp) | {p.get("win") for p in pairs} | {p.get("lose") for p in pairs}
    with open(os.path.join(OUT, "labels.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["id", "star", "down", "inspects", "pair_wins", "pair_losses", "why", "prompt_full",
                    "init_source", "steps", "size", "ref", "bestof", "bestof_pick", "particles", "particle_pick"])
        for rid in sorted(i for i in ids if i):
            t = trace(rid); a = t.get("arms") or {}
            w.writerow([rid, int(rid in stars), int(rid in downs), insp.get(rid, 0),
                        sum(1 for p in pairs if p.get("win") == rid), sum(1 for p in pairs if p.get("lose") == rid),
                        json.dumps(why.get(rid, [])), t.get("prompt_full", ""), t.get("init_source", ""),
                        t.get("steps", ""), t.get("size", ""), a.get("ref", ""), a.get("bestof", ""),
                        a.get("bestof_pick", ""), a.get("particles", ""), a.get("particle_pick", "")])

    same = sum(1 for r in rows if r["same_prompt"])
    man = {"built": datetime.datetime.now().isoformat(timespec="seconds"), "out": OUT,
           "lora_positives": n_lora, "lora_studio_positives": n_studio, "downs": len(downs),
           "dpo_pairs": len(rows), "dpo_pairs_same_prompt": same,
           "explicit_pairs": sum(1 for r in rows if r["kind"] == "pair"),
           "needs": {"style LoRA": "~50-200 consistent positives (have %d)" % n_lora,
                     "Diffusion-DPO / Flow-GRPO": "hundreds of SAME-PROMPT pairs (have %d); "
                                                  "best-of candidate sets are the natural source once EJ labels them" % same}}
    json.dump(man, open(os.path.join(OUT, "manifest.json"), "w"), indent=1)
    print(json.dumps(man))


if __name__ == "__main__":
    main()
