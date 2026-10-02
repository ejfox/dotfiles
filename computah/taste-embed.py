"""CLIP side of the muse wall's preference model — runs ON computah (CPU torch).

  python taste-embed.py embed
      CLIP-embed every muse-gallery render → render-embeds.npz (ids, vecs float16).
      Resumable, IDLE CPU priority, stops itself if a game/anti-cheat starts.
  python taste-embed.py score <probe.npz> <img> [<img> ...]
      For best-of-N: JSON per candidate {file, probe, maxsim, pick}. probe =
      preference-model logit; maxsim = highest cosine similarity to the cells
      currently on the wall. pick = argmax(probe - LAMBDA * maxsim) — the probe
      gives DIRECTION, the penalty forces spread (EJ rejected "similar to my
      favorites" as a quality signal because it collapses variety).

Model = ViT-B-32-quickgelu / openai — same as ~/roadtrip-rank/score.py.
Shipped by muse-taste-probe; source ~/.dotfiles/computah/taste-embed.py.
"""
import ctypes, glob, json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
GALLERY = r"C:\dev\computah\renders\muse-gallery"
WALL = r"C:\dev\computah\farm\sd"
OUT = os.path.join(HERE, "render-embeds.npz")
GAME = ("fortniteclient", "easyanticheat", "beservice", "battleye")
LAMBDA = float(os.environ.get("MUSE_BON_LAMBDA", "4.0"))

def gaming():
    out = subprocess.run(["tasklist", "/fo", "csv", "/nh"], capture_output=True, text=True).stdout.lower()
    return any(g in out for g in GAME)

def model():
    import open_clip, torch
    torch.set_num_threads(max(2, (os.cpu_count() or 4) // 2))
    m, _, pre = open_clip.create_model_and_transforms("ViT-B-32-quickgelu", pretrained="openai")
    m.eval()
    return m, pre

def embed_files(m, pre, paths):
    import torch
    from PIL import Image
    xs, ok = [], []
    for p in paths:
        try:
            xs.append(pre(Image.open(p).convert("RGB"))); ok.append(p)
        except Exception:
            pass
    if not xs:
        return [], None
    with torch.no_grad():
        f = m.encode_image(torch.stack(xs)).float()
    return ok, (f / f.norm(dim=-1, keepdim=True)).numpy()

def embed_all():
    import numpy as np
    try:
        ctypes.windll.kernel32.SetPriorityClass(ctypes.windll.kernel32.GetCurrentProcess(), 0x40)  # IDLE
    except Exception:
        pass
    ids, vecs = [], []
    if os.path.exists(OUT):
        z = np.load(OUT)
        ids, vecs = list(z["ids"]), [z["vecs"]]
    have = set(ids)
    todo = sorted(f for f in glob.glob(os.path.join(GALLERY, "muse-*.png")) if not f.endswith("-init.png")
                  and os.path.basename(f)[5:-4] not in have)
    if gaming():
        print("game running — not embedding"); return 3
    m, pre = model()
    for k in range(0, len(todo), 64):
        if gaming():
            print("game started — stopping (resumable)"); break
        ok, v = embed_files(m, pre, todo[k:k + 64])
        if v is not None:
            ids += [os.path.basename(p)[5:-4] for p in ok]; vecs.append(v.astype("float16"))
        if (k // 64) % 20 == 0:
            np.savez(OUT, ids=np.array(ids), vecs=np.concatenate(vecs))
            print(f"embedded {len(ids)} / {len(have) + len(todo)}", flush=True)
    np.savez(OUT, ids=np.array(ids), vecs=np.concatenate(vecs))
    print(f"done — {len(ids)} renders embedded", flush=True)
    return 0

def score(probe_path, files):
    import numpy as np
    p = np.load(probe_path)
    w, b = p["w"], float(p["b"])
    m, pre = model()
    ok, v = embed_files(m, pre, files)
    wall_files = [f for f in glob.glob(os.path.join(WALL, "wall_*.png")) if "-init" not in f]
    _, wv = embed_files(m, pre, wall_files)
    out = []
    for f, e in zip(ok, v):
        maxsim = float((wv @ e).max()) if wv is not None else 0.0
        out.append({"file": f, "probe": float(e @ w + b), "maxsim": round(maxsim, 4)})
    if out:
        best = max(out, key=lambda o: o["probe"] - LAMBDA * o["maxsim"])
        for o in out:
            o["pick"] = o is best
    print(json.dumps(out))
    return 0

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "embed":
        sys.exit(embed_all())
    if len(sys.argv) > 3 and sys.argv[1] == "score":
        sys.exit(score(sys.argv[2], sys.argv[3:]))
    print(__doc__); sys.exit(2)
