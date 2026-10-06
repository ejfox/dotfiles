"""TASTE JUDGE — a preference model of EJ's generated images. Validates itself; steers nothing.

  python taste_judge.py train [--data DIR] [--seen FILE] [--out judge-v1.npz]
      Build labels (★ / ▽ / pair / inspect) → honest out-of-fold validation of every
      model + baselines → fit the shipped heads on all data → judge-vN.npz + judge-vN.json.
  python taste_judge.py score [--domain flux|studio] [--no-wall] <img> [<img> ...]
      JSON list: {file, p_like, pct, logit, maxsim_to_wall, pick, ready}. Runs on computah
      (needs the CLIP venv); `taste-judge.cmd score ...` wraps it.
  python taste_judge.py info        → the shipped model's metrics.
  python taste_judge.py prospective --data DIR --seen auto
      FROZEN judge vs only the renders made after it was built — the real test.

Python:  from taste_judge import Judge
         j = Judge.load()                       # newest judge-v*.npz next to this file
         j.score_vecs(V, domain="flux")         # V = unit CLIP vectors (n, 512) → dicts
         j.score_paths(paths, wall=True)        # embeds with CLIP first
         j.ready("flux")                        # False ⇒ callers must NOT steer on it

LABELS (unlabeled renders are background, never negatives in the eval target):
  ★ positive   = renders\\favorites\\muse-*.png (FLUX) and favorites\\studio\\*.png (Blender)
  ▽ negative   = events type=down (latest state on)
  pair         = events type=pair → Bradley–Terry term on (win − lose)
  inspect      = weak positive, mass 0.5 (models are reported with AND without it)
  background   = every other embedded render, weak negative (class-balanced weight)

  seen pool    = the PRIMARY background: renders EJ was at the desk to see (muse_presence
                 .seen_flags — same as muse-taste-weights/-viz), favorite replays excluded.
                 `--seen auto` computes it on the Mac; `--seen labels.json` reuses the file.

EVAL: every item gets an out-of-fold score; AUC = held-out ★ vs held-out background;
precision@k over the pooled OOF ranking. Three splits: random stratified (5-fold),
leave-DAYS-out (5 folds grouped by render day), and TEMPORAL forward-chaining (5 day
blocks with equal ★; each block scored by a model trained only on earlier blocks — the
situation steering is actually in). Also reproduces the existing probe's own LOO number.
The STEER BAR: min(by-day AUC, temporal block-mean AUC) ≥ 0.65. Below it `ready` is false.

On the Mac:  muse-taste-probe pulls render-embeds.npz; for a judge run pull also
studio-embeds.npz, events.jsonl, render-scores.csv and the favorites listings into a
dir, then `taste_judge.py train --data DIR --seen auto --out DIR/judge-vN.npz`, scp
judge-vN.{npz,json} to C:\\Users\\ejfox\\farm\\taste\\. (`computah`-side: Judge.load()
picks the highest vN.)

Diversity: score() returns maxsim_to_wall (cosine to the cells on the wall) and
pick = argmax(logit − LAMBDA·maxsim): the judge gives DIRECTION, the penalty keeps
the wall from collapsing onto its favorites (EJ's rule — similarity-to-a-favorite is
the wrong signal).
"""
import csv, glob, json, math, os, sys, time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
EVENTS = r"C:\dev\computah\farm\sd\taste\events.jsonl"
FAVS = r"C:\dev\computah\renders\favorites"
STUDIO_FAVS = r"C:\dev\computah\renders\favorites\studio"
WALL = r"C:\dev\computah\farm\sd"
LAMBDA = float(os.environ.get("MUSE_BON_LAMBDA", "4.0"))
STEER_AUC = 0.65
INSPECT_MASS = 0.5
SEEDS = 3

# ───────────────────────── fitting ─────────────────────────

def sigmoid(z):
    return 1 / (1 + np.exp(-np.clip(z, -40, 40)))

def fit_lr(X, y, w, lam, pairs=None, pair_w=1.0, iters=25):
    """Weighted L2 logistic regression by IRLS/Newton (exact, fast for d ≤ ~600).
    pairs: (Xwin − Xlose) rows → Bradley–Terry term log σ(β·Δ), weight pair_w each."""
    n, d = X.shape
    A = np.hstack([X, np.ones((n, 1))])
    if pairs is not None and len(pairs):
        D = np.hstack([pairs, np.zeros((len(pairs), 1))])   # bias cancels in a difference
        A = np.vstack([A, D]); y = np.concatenate([y, np.ones(len(D))])
        w = np.concatenate([w, np.full(len(D), pair_w)])
    beta = np.zeros(d + 1)
    R = lam * np.eye(d + 1); R[-1, -1] = 1e-6
    for _ in range(iters):
        p = sigmoid(A @ beta)
        g = A.T @ (w * (p - y)) + R @ beta
        H = (A * (w * p * (1 - p))[:, None]).T @ A + R
        step = np.linalg.solve(H, g)
        beta -= step
        if np.abs(step).max() < 1e-6:
            break
    return beta[:-1], float(beta[-1])

def auc(pos, neg):
    pos, neg = np.asarray(pos, float), np.asarray(neg, float)
    if not len(pos) or not len(neg):
        return None
    allv = np.concatenate([pos, neg])
    order = allv.argsort(kind="mergesort")
    ranks = np.empty(len(allv)); ranks[order] = np.arange(1, len(allv) + 1)
    # average ties
    _, inv, cnt = np.unique(allv, return_inverse=True, return_counts=True)
    sums = np.bincount(inv, ranks); ranks = (sums / cnt)[inv]
    return float((ranks[:len(pos)].sum() - len(pos) * (len(pos) + 1) / 2) / (len(pos) * len(neg)))

def prec_at(scores, is_pos, ks=(10, 25, 50)):
    o = np.argsort(-scores)
    return {k: float(is_pos[o[:k]].mean()) for k in ks if k <= len(o)}

# ───────────────────────── data ─────────────────────────

def load_npz(path):
    z = np.load(path)
    return [str(i) for i in z["ids"]], z["vecs"].astype(np.float64)

def listdir_ids(data, txt, d, prefix="", suffix=".png"):
    """Favorite ids from a directory (on the PC) or a pulled listing file (on the Mac)."""
    f = os.path.join(data, txt)
    if os.path.exists(f):
        names = [l.strip() for l in open(f, encoding="utf-8") if l.strip()]
    elif os.path.isdir(d):
        names = os.listdir(d)
    else:
        return set()
    return {n[len(prefix):-len(suffix)] for n in names if n.startswith(prefix) and n.endswith(suffix)}

def load_events(path):
    down, insp, pairs, why = {}, {}, [], []
    if not os.path.exists(path):
        return set(), {}, [], []
    for line in open(path, encoding="utf-8"):
        try:
            e = json.loads(line)
        except ValueError:
            continue
        t = e.get("type")
        if t == "down":
            down[e["id"]] = bool(e.get("on", True))
        elif t == "inspect":
            insp[e["id"]] = insp.get(e["id"], 0) + 1
        elif t == "pair" and e.get("win") and e.get("lose"):
            pairs.append((e["win"], e["lose"]))
        elif t == "why":
            why.append(e)
    return {i for i, on in down.items() if on}, insp, pairs, why

def knob_rows(path):
    rows = {}
    if os.path.exists(path):
        for r in csv.DictReader(open(path, newline="", encoding="utf-8")):
            rows[r["id"]] = r
    return rows

def knob_tokens(r):
    """Discrete knob features for the comparison model / prior baseline."""
    if r is None:
        return ["unk"]
    src = r.get("init_source", "") or "?"
    style = (r.get("style") or "").split(",")[0].strip().lower() or "none"
    team = (r.get("team") or "none").split("·")[-1]
    pf = r.get("prompt_from", "")
    pf = "replay" if "replay" in pf else "bank" if "prompt-bank" in pf else "remix" if "remix" in pf else (pf[:12] or "?")
    try:
        st = int(float(r.get("steps") or 0)); stb = "s<20" if st < 20 else "s<30" if st < 30 else "s30+"
    except ValueError:
        stb = "s?"
    try:
        stg = float(r.get("strength") or -1); sgb = "str-none" if stg < 0 else "str<.6" if stg < .6 else "str.6+"
    except ValueError:
        sgb = "str?"
    return [f"pure={src == 'pure'}", f"src={src.split('+')[0]}", f"style={style}", f"team={team}",
            f"sampler={r.get('sampler') or '?'}", f"size={r.get('size') or '?'}", f"pf={pf}", stb, sgb]

def onehot(tok_lists, vocab=None, min_count=1):
    if vocab is None:
        cnt = {}
        for ts in tok_lists:
            for t in ts:
                cnt[t] = cnt.get(t, 0) + 1
        vocab = {t: k for k, t in enumerate(sorted(t for t, c in cnt.items() if c >= min_count))}
    M = np.zeros((len(tok_lists), len(vocab)))
    for i, ts in enumerate(tok_lists):
        for t in ts:
            if t in vocab:
                M[i, vocab[t]] = 1
    return M, vocab

# ───────────────────────── models (all fit on a train mask, score everything) ─────────────────────────

class Ctx:
    """Everything a model needs for one domain."""
    def __init__(self, ids, X, pos, neg, insp, pairs, knobs=None):
        self.ids, self.X = ids, X
        self.n = len(ids)
        self.idx = {i: k for k, i in enumerate(ids)}
        self.pos = np.array([i in pos for i in ids])
        self.neg = np.array([i in neg and i not in pos for i in ids])
        self.insp = np.array([i in insp and i not in pos for i in ids])
        self.pairs = [(self.idx[a], self.idx[b]) for a, b in pairs if a in self.idx and b in self.idx]
        self.knobs = knobs
        self.day = np.array([i[:8] for i in ids])
        self.ts = np.array([float(i[:8] + i[9:15]) if i[8:9] == "-" and i[9:15].isdigit() else 0 for i in ids])

def weights(c, m, use_insp, use_neg=True):
    """Balanced weights on the training mask m: positives (★=1, inspect=0.5) vs background."""
    y = np.zeros(c.n); w = np.zeros(c.n)
    P = m & c.pos; I = m & c.insp if use_insp else np.zeros(c.n, bool)
    y[P] = 1; w[P] = 1.0
    y[I] = 1; w[I] = INSPECT_MASS
    B = m & ~P & ~I
    pmass = w[P | I].sum()
    if use_neg:
        Nd = B & c.neg
        Bg = B & ~c.neg
        w[Nd] = 1.0
    else:
        Nd = np.zeros(c.n, bool); Bg = B
    w[Bg] = max(pmass - w[Nd].sum(), 0.2 * pmass) / max(Bg.sum(), 1)
    return y, w

def standardize(X, m):
    mu = X[m].mean(0); sd = X[m].std(0) + 1e-6
    return mu, sd

def m_clip_lr(lam, use_insp, use_pairs, pca=0):
    def run(c, m):
        mu, sd = standardize(c.X, m)
        Z = (c.X - mu) / sd
        if pca:
            _, _, Vt = np.linalg.svd(Z[m][::max(1, m.sum() // 4000)], full_matrices=False)
            Z = Z @ Vt[:pca].T
        y, w = weights(c, m, use_insp)
        pr = None
        if use_pairs:
            pr = np.array([Z[a] - Z[b] for a, b in c.pairs if m[a] and m[b]]).reshape(-1, Z.shape[1])
        tr = m & (w > 0)
        beta, b = fit_lr(Z[tr], y[tr], w[tr], lam, pairs=pr)
        return Z @ beta + b
    return run

def m_centroid(use_insp):
    """Direction only: cos(x, mean★ − mean background). The simplest 'probe'."""
    def run(c, m):
        P = m & c.pos
        Pw = np.ones(P.sum())
        Xp = c.X[P]
        if use_insp and (m & c.insp).any():
            Xp = np.vstack([Xp, c.X[m & c.insp]]); Pw = np.concatenate([Pw, np.full((m & c.insp).sum(), INSPECT_MASS)])
        d = (Xp * Pw[:, None]).sum(0) / Pw.sum() - c.X[m & ~c.pos].mean(0)
        return c.X @ (d / np.linalg.norm(d))
    return run

def m_maxsim():
    """The rejected naive signal, for reference: max cosine to any training ★."""
    def run(c, m):
        S = c.X @ c.X[m & c.pos].T
        return S.max(1)
    return run

def m_knob_lr(lam):
    def run(c, m):
        K = c.knobs
        y, w = weights(c, m, False)
        tr = m & (w > 0)
        beta, b = fit_lr(K[tr], y[tr], w[tr], lam)
        return K @ beta + b
    return run

def m_prior():
    """Baseline: pure-txt2img + crew + style priors (smoothed log-odds, additive)."""
    def run(c, m):
        toks = c.tok
        base = c.pos[m].mean()
        s = np.zeros(c.n)
        for fam in ("pure=", "team=", "style="):
            rate = {}
            for k in np.where(m)[0]:
                t = next((t for t in toks[k] if t.startswith(fam)), None)
                if t:
                    a = rate.setdefault(t, [0, 0]); a[0] += c.pos[k]; a[1] += 1
            for k in range(c.n):
                t = next((t for t in toks[k] if t.startswith(fam)), None)
                pp, nn = rate.get(t, (0, 0))
                s[k] += math.log((pp + 20 * base) / (nn + 20) / base)
        return s
    return run

def m_combo(lam, use_insp):
    """CLIP (PCA-64) + knob one-hots in one regularized LR."""
    def run(c, m):
        mu, sd = standardize(c.X, m)
        Z = (c.X - mu) / sd
        _, _, Vt = np.linalg.svd(Z[m][::max(1, m.sum() // 4000)], full_matrices=False)
        F = np.hstack([Z @ Vt[:64].T, c.knobs])
        y, w = weights(c, m, use_insp)
        tr = m & (w > 0)
        beta, b = fit_lr(F[tr], y[tr], w[tr], lam)
        return F @ beta + b
    return run

def m_oldprobe(use_mass=True):
    """The EXISTING probe (muse-taste-probe, 2026-09-30) recipe, verbatim: raw unit CLIP
    vectors, positive = any positive mass (★ 1 · inspect 0.5 · pair win 0.5), unlabeled
    weight 0.05, class-balanced, L2=1.0, 200 GD steps at lr 0.5."""
    def run(c, m):
        y = (c.mass > 0).astype(float) if use_mass else c.pos.astype(float)
        w = np.where(y == 1, c.mass if use_mass else 1.0, np.where(c.negmass > 0, c.negmass, 0.05))
        tr = m.copy()
        if y[tr].sum():
            w = np.where(y == 1, w * (w[tr & (y == 0)].sum() / w[tr & (y == 1)].sum()), w)
        X, yy, ww = c.X[tr], y[tr], w[tr]
        sw = ww / ww.sum(); wt = np.zeros(X.shape[1]); b = 0.0
        for _ in range(200):
            g = sigmoid(X @ wt + b) - yy
            wt -= 0.5 * (X.T @ (sw * g) + 1.0 * wt / len(yy)); b -= 0.5 * float(sw @ g)
        return c.X @ wt + b
    return run

def head_params(name, c, m):
    """Refit a CLIP-only candidate on mask m and return its linear form:
    logit = ((x − mu) / sd) · w + b, so score() needs nothing but these four."""
    d = c.X.shape[1]
    if name.startswith("existing"):
        use_mass = "only" not in name
        y = (c.mass > 0).astype(float) if use_mass else c.pos.astype(float)
        w = np.where(y == 1, c.mass if use_mass else 1.0, np.where(c.negmass > 0, c.negmass, 0.05))
        w = np.where(y == 1, w * (w[m & (y == 0)].sum() / w[m & (y == 1)].sum()), w)
        X, yy, ww = c.X[m], y[m], w[m]
        sw = ww / ww.sum(); wt = np.zeros(d); b = 0.0
        for _ in range(400):
            g = sigmoid(X @ wt + b) - yy
            wt -= 0.5 * (X.T @ (sw * g) + 1.0 * wt / len(yy)); b -= 0.5 * float(sw @ g)
        return np.zeros(d), np.ones(d), wt, b
    if name.startswith("clip centroid"):
        P = m & c.pos; Xp = c.X[P]; Pw = np.ones(P.sum())
        if "insp" in name:
            Xp = np.vstack([Xp, c.X[m & c.insp]]); Pw = np.concatenate([Pw, np.full((m & c.insp).sum(), INSPECT_MASS)])
        v = (Xp * Pw[:, None]).sum(0) / Pw.sum() - c.X[m & ~c.pos].mean(0)
        return np.zeros(d), np.ones(d), v / np.linalg.norm(v), 0.0
    lam = float(name.split("λ=")[1])
    use_insp, use_pairs = "insp" in name, "pairs" in name
    mu, sd = standardize(c.X, m)
    Z = (c.X - mu) / sd
    y, w = weights(c, m, use_insp)
    pr = np.array([Z[a] - Z[b] for a, b in c.pairs if m[a] and m[b]]).reshape(-1, d) if use_pairs else None
    tr = m & (w > 0)
    beta, b = fit_lr(Z[tr], y[tr], w[tr], lam, pairs=pr)
    return mu, sd, beta, b

def m_recency():
    def run(c, m):
        return c.ts.copy()
    return run

def m_ejtaste():
    def run(c, m):
        return c.ejtaste.copy()
    return run

# ───────────────────────── evaluation ─────────────────────────

def folds(c, k, seed, grouped, eval_mask):
    rng = np.random.default_rng(seed)
    f = np.full(c.n, -1)
    if grouped == "temporal":
        # k contiguous blocks of DAYS, cut so each block holds ~equal ★; oof() trains
        # only on blocks strictly before the test block (forward-chaining, no future info)
        days = sorted(set(c.day[eval_mask]))
        cum = np.cumsum([(c.pos & eval_mask & (c.day == d)).sum() for d in days])
        tot = cum[-1] if len(cum) else 0
        dayf = {d: min(k - 1, int(k * (cum[j] - 0.5) / max(tot, 1))) for j, d in enumerate(days)}
        for i in np.where(eval_mask)[0]:
            f[i] = dayf[c.day[i]]
        return f
    if grouped:
        days = sorted(set(c.day[eval_mask]))
        rng.shuffle(days)
        # balance stars across folds: greedy by star count
        load = np.zeros(k); dayf = {}
        for d in sorted(days, key=lambda d: -(c.pos & (c.day == d)).sum()):
            j = int(np.argmin(load + rng.random(k) * 1e-3)); dayf[d] = j
            load[j] += (c.pos & (c.day == d)).sum() + 1e-3 * (c.day == d).sum()
        for i in np.where(eval_mask)[0]:
            f[i] = dayf[c.day[i]]
    else:
        for cls in (c.pos & eval_mask, ~c.pos & eval_mask):
            ix = np.where(cls)[0]; rng.shuffle(ix)
            f[ix] = np.arange(len(ix)) % k
    return f

def oof(c, model, k, seed, grouped, eval_mask):
    f = folds(c, k, seed, grouped, eval_mask)
    s = np.full(c.n, np.nan)
    for j in range(k):
        te = f == j
        if not (te & c.pos).any():
            continue
        tr = ((f >= 0) & (f < j)) if grouped == "temporal" else ((f >= 0) & ~te)
        if not (tr & c.pos).any():
            continue
        s[te] = model(c, tr)[te]
    return s

def summarize(c, s, eval_mask, bg_mask=None):
    bg = eval_mask & ~c.pos & ~np.isnan(s) if bg_mask is None else bg_mask & ~c.pos & ~np.isnan(s)
    P = eval_mask & c.pos & ~np.isnan(s)
    out = {"auc": auc(s[P], s[bg])}
    pool = (P | bg)
    out["p@k"] = prec_at(s[pool], c.pos[pool])
    out["top5%_recall"] = float((s[P] >= np.quantile(s[pool], 0.95)).mean()) if P.any() else None
    # side checks on the same OOF scores
    I = eval_mask & c.insp & ~c.pos & ~np.isnan(s)
    out["inspect_vs_bg"] = auc(s[I], s[bg & ~c.insp]) if I.sum() >= 3 else None
    D = eval_mask & c.neg & ~np.isnan(s)
    out["star_vs_down"] = auc(s[P], s[D]) if D.any() else None
    pr = [(a, b) for a, b in c.pairs if not (np.isnan(s[a]) or np.isnan(s[b]))]
    out["pairs_right"] = f"{sum(s[a] > s[b] for a, b in pr)}/{len(pr)}" if pr else None
    return out

def evaluate(c, models, eval_mask, k=5, seeds=SEEDS, bg_mask=None, log=print):
    res = {}
    for name, (model, needs) in models.items():
        row = {}
        for split in ("random", "by-day", "temporal"):
            runs = []
            for sd in range(1 if needs == "none" or split == "temporal" else seeds):
                grouped = {"random": False, "by-day": True, "temporal": "temporal"}[split]
                if needs == "none":
                    s = model(c, eval_mask)
                    if split == "temporal":   # same test blocks as the trained models see
                        f = folds(c, k, 0, "temporal", eval_mask)
                        s = np.where(f >= 1, s, np.nan)
                    s = np.where(eval_mask, s, np.nan)
                else:
                    s = oof(c, model, k, sd, grouped, eval_mask)
                runs.append(summarize(c, s, eval_mask, bg_mask))
                if split == "temporal":
                    # per-block AUC (each block has its own model — pooled AUC mixes scales)
                    f = folds(c, k, 0, "temporal", eval_mask)
                    blk = []
                    for j in range(1, k):
                        te = (f == j) & ~np.isnan(s)
                        blk.append(auc(s[te & c.pos], s[te & ~c.pos]) if (te & c.pos).any() else None)
                    runs[-1]["blocks"] = blk
            a = [r["auc"] for r in runs if r["auc"] is not None]
            row[split] = {"auc": round(float(np.mean(a)), 3) if a else None,
                          "auc_sd": round(float(np.std(a)), 3) if a else None,
                          "p@k": {kk: round(float(np.mean([r["p@k"].get(kk, 0) for r in runs])), 3) for kk in runs[0]["p@k"]},
                          "top5%_recall": round(float(np.mean([r["top5%_recall"] for r in runs])), 3),
                          "inspect_vs_bg": None if runs[0]["inspect_vs_bg"] is None else round(float(np.mean([r["inspect_vs_bg"] for r in runs])), 3),
                          "star_vs_down": None if runs[0]["star_vs_down"] is None else round(float(np.mean([r["star_vs_down"] for r in runs])), 3),
                          "pairs_right": runs[0]["pairs_right"]}
            if split == "temporal":
                blk = [b for b in runs[0].get("blocks", []) if b is not None]
                row[split]["blocks"] = [None if b is None else round(b, 3) for b in runs[0].get("blocks", [])]
                row[split]["block_mean"] = round(float(np.mean(blk)), 3) if blk else None
        res[name] = row
        r, g, t = row["random"], row["by-day"], row["temporal"]
        log(f"  {name:30} AUC random {r['auc']}±{r['auc_sd']}  by-day {g['auc']}±{g['auc_sd']}  "
            f"temporal pooled {t['auc']} blocks {t.get('blocks')} mean {t.get('block_mean')}  "
            f"| by-day p@10/25/50 {list(g['p@k'].values())} top5%-recall {g['top5%_recall']}  "
            f"insp>bg {g['inspect_vs_bg']}  ★>▽ {g['star_vs_down']}  pairs {g['pairs_right']}")
    return res

# ───────────────────────── train ─────────────────────────

def arg(flag, default=None):
    return sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else default

def train():
    data = arg("--data", HERE)
    out = arg("--out", os.path.join(HERE, "judge-v1.npz"))
    seen_arg = arg("--seen")
    lines = []
    def log(s=""):
        print(s, flush=True); lines.append(s)

    ev_path = os.path.join(data, "events.jsonl") if os.path.exists(os.path.join(data, "events.jsonl")) else EVENTS
    down, insp, pairs, why = load_events(ev_path)
    fav = listdir_ids(data, "favorites.txt", FAVS, "muse-")
    sfav = listdir_ids(data, "studio-favorites.txt", STUDIO_FAVS)
    knobs = knob_rows(os.path.join(data, "render-scores.csv"))

    # ── FLUX domain
    ids, X = load_npz(os.path.join(data, "render-embeds.npz"))
    c = Ctx(ids, X, fav, down, insp, pairs)
    c.tok = [knob_tokens(knobs.get(i)) for i in ids]
    c.knobs, vocab = onehot(c.tok, min_count=5)
    c.ejtaste = np.array([float(knobs[i]["ejtaste"]) if i in knobs and knobs[i]["ejtaste"] else 0.0 for i in ids])
    wins = {}
    for a, _ in pairs:
        wins[a] = wins.get(a, 0) + 1
    # positive mass exactly as muse-taste-weights: ★ 1 · inspected 0.5 · each pair win 0.5
    c.mass = np.array([(i in fav) * 1.0 + (i in insp) * 0.5 + 0.5 * wins.get(i, 0) for i in ids])
    losses = {}
    for _, b in pairs:
        losses[b] = losses.get(b, 0) + 1
    c.negmass = np.array([(i in down) * 1.0 + 0.25 * losses.get(i, 0) for i in ids])
    replay = np.array([knobs.get(i, {}).get("prompt_from") == "favorite replay" for i in ids])
    missing = sorted(fav - set(ids))
    log(f"◆ TASTE JUDGE training {time.strftime('%Y-%m-%d %H:%M')}")
    log(f"◆ FLUX: {c.n} embedded renders · ★ {c.pos.sum()} (of {len(fav)} favorites; {len(missing)} not embedded)"
        f" · ▽ {c.neg.sum()} · inspected-not-★ {c.insp.sum()} · pairs {len(c.pairs)}/{len(pairs)} · why-notes {len(why)}")
    allm = np.ones(c.n, bool)
    stars_pure = sum(1 for i in ids if i in fav and knobs.get(i, {}).get("init_source") == "pure")
    log(f"  ★ that are pure txt2img: {stars_pure}/{c.pos.sum()} · pure share of all renders "
        f"{np.mean([knobs.get(i, {}).get('init_source') == 'pure' for i in ids]):.2f}"
        f" · ★ that are favorite-replays: {(c.pos & replay).sum()}")

    # EXPOSURE (the right negative set): renders EJ was at the desk to see, minus favorite
    # replays — same definition as muse-taste-weights / muse-taste-viz (muse_presence.seen_flags).
    seen = None
    if seen_arg == "auto":
        sys.path.insert(0, os.path.expanduser("~/.dotfiles/bin"))
        import muse_presence as MP
        sf = MP.seen_flags(list(knobs.values()))
        seen = {i for i, v in sf.items() if v}
    elif seen_arg and os.path.exists(seen_arg):
        sj = json.load(open(seen_arg))
        seen = set(sj["rows"]) if isinstance(sj, dict) and "rows" in sj else set(sj)
    if seen is not None:
        sm = np.array([(i in seen or i in fav) for i in ids]) & ~replay
        log(f"  seen (exposure) pool: {sm.sum()} renders, non-replay, ★ {(sm & c.pos).sum()} · "
            f"positive mass {c.mass[sm].sum():.1f}")
    else:
        sm = ~replay
        log("  ◇ no --seen: exposure pool falls back to all non-replay renders")

    # ── 1. reproduce the existing probe's LOO number with ITS protocol
    log("\n── existing probe (muse-taste-probe) reproduced with its own LOO protocol ──")
    pool = np.where(sm)[0]
    P = pool[c.mass[pool] > 0]; U = pool[c.mass[pool] == 0]
    rng = np.random.default_rng(0)
    held_u = rng.choice(U, size=min(1000, len(U) // 5), replace=False)
    keep = sm.copy(); keep[held_u] = False
    run_old = m_oldprobe(True)
    sp, su = [], None
    for k in P:
        mm = keep.copy(); mm[k] = False
        sc = run_old(c, mm)
        sp.append(sc[k])
        if su is None:
            su = sc[held_u]
    sp = np.array(sp)
    old_loo = auc(sp, su)
    star_in_P = c.pos[P]
    log(f"  positives {len(P)} (★ {star_in_P.sum()}, inspect/pair-only {(~star_in_P).sum()}), mass {c.mass[P].sum():.1f}"
        f" → LOO AUC {old_loo:.3f}  [★ only {auc(sp[star_in_P], su):.3f} · inspect-only {auc(sp[~star_in_P], su):.3f}]")
    # leakage probe: how close is each held-out positive to its nearest OTHER positive?
    S = c.X[P] @ c.X[P].T; np.fill_diagonal(S, -1)
    nn = S.max(1); nnj = S.argmax(1)
    same_day = np.array([c.day[P[a]] == c.day[P[b]] for a, b in enumerate(nnj)])
    near = nn > 0.9
    log(f"  near-duplicates: {near.sum()}/{len(P)} positives have another positive at cos>0.9 "
        f"({(near & same_day).sum()} of those on the same day); median nearest-positive cos {np.median(nn):.3f}")
    if near.any():
        log(f"  LOO AUC without near-dup positives: {auc(sp[~near], su):.3f}")
    old = {"loo_auc_repro": round(old_loo, 3), "loo_star_only": round(auc(sp[star_in_P], su), 3),
           "loo_inspect_only": round(auc(sp[~star_in_P], su), 3) if (~star_in_P).any() else None,
           "n_pos": int(len(P)), "near_dup_pos": int(near.sum())}

    # ── 2. every model under stricter splits. Target = ★ only; inspects only train.
    models = {
        "baseline: recency (ts)": (m_recency(), "none"),
        "baseline: photo ejtaste": (m_ejtaste(), "none"),
        "baseline: pure+crew+style prior": (m_prior(), "train"),
        "knob LR (λ=10)": (m_knob_lr(10.0), "train"),
        "naive maxsim-to-★": (m_maxsim(), "train"),
        "existing probe recipe": (m_oldprobe(True), "train"),
        "existing recipe, ★ only": (m_oldprobe(False), "train"),
        "clip centroid ★": (m_centroid(False), "train"),
        "clip centroid ★+insp": (m_centroid(True), "train"),
        "clip LR λ=100": (m_clip_lr(100.0, False, False), "train"),
        "clip LR λ=1000": (m_clip_lr(1000.0, False, False), "train"),
        "clip LR+insp λ=100": (m_clip_lr(100.0, True, False), "train"),
        "clip LR+insp λ=1000": (m_clip_lr(1000.0, True, False), "train"),
        "clip LR+insp+pairs λ=100": (m_clip_lr(100.0, True, True), "train"),
        "clip PCA64+knobs LR λ=10": (m_combo(10.0, False), "train"),
        "clip PCA64+knobs+insp λ=10": (m_combo(10.0, True), "train"),
    }
    log(f"\n── FLUX PRIMARY: held-out ★ vs SEEN background ({sm.sum()} renders) · random 5×{SEEDS} / by-day 5×{SEEDS} / temporal forward ──")
    res = {"seen": evaluate(c, models, sm, log=log)}
    log(f"\n── FLUX: held-out ★ vs ALL renders incl. unseen ({c.n}) ──")
    res["all"] = evaluate(c, {k: models[k] for k in ("baseline: recency (ts)", "baseline: pure+crew+style prior",
                                                     "existing probe recipe", "clip LR λ=100", "clip LR+insp λ=100")},
                          allm, log=log)
    pm = sm & np.array([knobs.get(i, {}).get("init_source") == "pure" for i in ids])
    log(f"\n── FLUX: seen pure-txt2img only ({pm.sum()} renders, {(pm & c.pos).sum()} ★) — does CLIP add beyond the 'pure' prior? ──")
    keep = ["baseline: recency (ts)", "baseline: pure+crew+style prior", "knob LR (λ=10)", "existing probe recipe",
            "clip centroid ★", "clip LR λ=100", "clip LR+insp λ=100", "clip PCA64+knobs LR λ=10"]
    res["pure"] = evaluate(c, {k: models[k] for k in keep}, pm, log=log)

    # ── Studio domain
    sres = {}
    sp = os.path.join(data, "studio-embeds.npz")
    shead = None
    if os.path.exists(sp):
        sids, SX = load_npz(sp)
        s = Ctx(sids, SX, sfav, down, insp, pairs)
        log(f"\n◆ STUDIO: {s.n} embedded pieces · ★ {s.pos.sum()} (of {len(sfav)})")
        smodels = {"baseline: recency (ts)": (m_recency(), "none"),
                   "clip centroid ★": (m_centroid(False), "train"),
                   "naive maxsim-to-★": (m_maxsim(), "train"),
                   "clip LR λ=100": (m_clip_lr(100.0, False, False), "train"),
                   "clip LR λ=1000": (m_clip_lr(1000.0, False, False), "train")}
        if s.pos.sum() >= 3:
            k = int(min(5, s.pos.sum()))
            log(f"── STUDIO: held-out ★ vs all pieces ({k}-fold) ──")
            sres["all"] = evaluate(s, smodels, np.ones(s.n, bool), k=k, log=log)
            first = min(i[:8] for i in sids if i in sfav)
            win = np.array([i[:8] >= first for i in sids])
            log(f"── STUDIO: only pieces made since the first studio ★ day ({first}; {win.sum()} pieces) ──")
            sres["since_first_star"] = evaluate(s, smodels, win, k=k, log=log)
        # transfer: does the FLUX taste direction rank studio ★ at all?
        mu, sd = standardize(c.X, allm)
        y, w = weights(c, allm, False)
        beta, b = fit_lr((c.X - mu) / sd, y, w, 100.0)
        t = ((SX - mu) / sd) @ beta + b
        sres["flux_judge_on_studio_auc"] = auc(t[s.pos], t[~s.pos])
        recent = np.array([i[:8] >= "20261005" for i in sids])
        sres["flux_judge_on_studio_auc_since_star_day"] = auc(t[s.pos & recent], t[~s.pos & recent])
        log(f"  transfer: FLUX-trained clip LR ranks studio ★ vs pieces at AUC {sres['flux_judge_on_studio_auc']:.3f}"
            f" (vs pieces since 20261005 only: {sres['flux_judge_on_studio_auc_since_star_day']:.3f})")
        if s.pos.sum() >= 1:
            smu, ssd = standardize(SX, np.ones(s.n, bool))
            yy, ww = weights(s, np.ones(s.n, bool), False)
            sb, sb0 = fit_lr((SX - smu) / ssd, yy, ww, 1000.0)
            shead = (smu, ssd, sb, sb0, (SX - smu) / ssd @ sb + sb0, s.pos)

    # ── ship: the CLIP-only head with the best WORST-CASE of (by-day, temporal) on the seen
    # pool. (Knob models can't score a bare image, so they're comparison-only.) Picking
    # the max of a handful of candidates is itself mildly optimistic — noted in the report.
    R = res["seen"]
    g = lambda name, key="by-day": (R[name][key].get("block_mean") if key == "temporal" else R[name][key]["auc"]) or 0
    cands = ["existing probe recipe", "existing recipe, ★ only", "clip centroid ★", "clip centroid ★+insp",
             "clip LR λ=100", "clip LR λ=1000", "clip LR+insp λ=100", "clip LR+insp λ=1000", "clip LR+insp+pairs λ=100"]
    name = max(cands, key=lambda n: (min(g(n), g(n, "temporal")), g(n)))
    strict = min(g(name), g(name, "temporal"))
    mu, sd, beta, b = head_params(name, c, sm)
    full = ((c.X - mu) / sd) @ beta + b
    s_oof = oof(c, models[name][0], 5, 0, True, sm)
    # Platt calibration on out-of-fold (by-day) logits at the real seen-★ base rate
    ok = ~np.isnan(s_oof)
    pa, pb = fit_lr(s_oof[ok, None], c.pos[ok].astype(float), np.ones(ok.sum()), 1e-3)
    ready = strict >= STEER_AUC
    base = {k: {s: R[k][s]["auc"] for s in ("random", "by-day", "temporal")} for k in R if k.startswith("baseline")}
    metrics = {"version": os.path.basename(out)[:-4], "built": time.strftime("%Y-%m-%d %H:%M"),
               "labels": {"flux_stars": int(c.pos.sum()), "flux_down": int(c.neg.sum()),
                          "flux_inspect_not_star": int(c.insp.sum()), "pairs": len(c.pairs),
                          "seen_pool": int(sm.sum()), "seen_stars": int((sm & c.pos).sum()),
                          "studio_stars": int(len(sfav)), "why_notes": len(why), "flux_renders": c.n},
               "existing_probe": old,
               "shipped_flux_head": name,
               "shipped_auc": {"random": g(name, "random"), "by-day": g(name), "temporal_block_mean": g(name, "temporal"),
                               "temporal_pooled": R[name]["temporal"]["auc"], "temporal_blocks": R[name]["temporal"].get("blocks")},
               "baselines_seen": base,
               "steer_bar": STEER_AUC, "steer_rule": "min(by-day, temporal block-mean) AUC on seen pool >= bar",
               "ready_flux": bool(ready), "ready_studio": False,
               "results": res, "studio": sres}
    if shead and sres.get("since_first_star"):
        sa = sres["since_first_star"]["clip LR λ=1000"]["by-day"]["auc"] or 0
        metrics["ready_studio"] = bool(sa >= STEER_AUC and len(sfav) >= 20)
    log(f"\n◆ existing probe: its own LOO {old['loo_auc_repro']} (★-only {old['loo_star_only']})")
    log(f"◆ shipped FLUX head: {name} · seen-pool AUC random {g(name, 'random')} · by-day {g(name)} · "
        f"temporal {g(name, 'temporal')} → strict {strict:.3f} {'CLEARS' if ready else 'is BELOW'} the {STEER_AUC} steer bar")
    pack = dict(mu=mu.astype(np.float32), sd=sd.astype(np.float32), w=beta.astype(np.float32), b=np.float32(b),
                platt=np.array([pa[0], pb], np.float32), bg_logits=np.sort(full[sm & ~c.pos]).astype(np.float32),
                metrics=json.dumps(metrics))
    if shead:
        smu, ssd, sb, sb0, sfull, spos = shead
        pack.update(s_mu=smu.astype(np.float32), s_sd=ssd.astype(np.float32), s_w=sb.astype(np.float32),
                    s_b=np.float32(sb0), s_bg_logits=np.sort(sfull[~spos]).astype(np.float32))
    np.savez(out, **pack)
    json.dump(metrics, open(out[:-4] + ".json", "w"), indent=1)
    open(out[:-4] + "-report.txt", "w", encoding="utf-8").write("\n".join(lines) + "\n")
    log(f"◆ wrote {out} (+ .json, -report.txt)")
    return 0

# ───────────────────────── scoring interface ─────────────────────────

class Judge:
    def __init__(self, path):
        self.path = path
        z = np.load(path)
        self.z = {k: z[k] for k in z.files}
        self.metrics = json.loads(str(self.z["metrics"]))
        self._clip = None

    @classmethod
    def load(cls, path=None):
        if path is None:
            cands = sorted(glob.glob(os.path.join(HERE, "judge-v*.npz")),
                           key=lambda p: int("".join(ch for ch in os.path.basename(p)[7:-4] if ch.isdigit()) or 0))
            if not cands:
                raise FileNotFoundError("no judge-v*.npz next to taste_judge.py — run train")
            path = cands[-1]
        return cls(path)

    def ready(self, domain="flux"):
        return bool(self.metrics.get(f"ready_{domain}", False))

    def logits(self, V, domain="flux"):
        p = "s_" if domain == "studio" else ""
        if p + "w" not in self.z:
            raise ValueError(f"judge has no {domain} head")
        return ((V - self.z[p + "mu"]) / self.z[p + "sd"]) @ self.z[p + "w"] + float(self.z[p + "b"])

    def score_vecs(self, V, domain="flux", wall_vecs=None, files=None):
        V = np.asarray(V, np.float64)
        L = self.logits(V, domain)
        bg = self.z["s_bg_logits" if domain == "studio" else "bg_logits"]
        pa, pb = self.z["platt"]
        out = []
        for k, l in enumerate(L):
            o = {"file": files[k] if files else k,
                 "p_like": round(float(sigmoid(pa * l + pb)), 5) if domain == "flux" else None,
                 "pct": round(float(np.searchsorted(bg, l) / len(bg)), 4),
                 "logit": round(float(l), 3)}
            o["maxsim_to_wall"] = round(float((wall_vecs @ V[k]).max()), 4) if wall_vecs is not None and len(wall_vecs) else None
            o["ready"] = self.ready(domain)
            out.append(o)
        if out:
            best = max(out, key=lambda o: o["logit"] - LAMBDA * (o["maxsim_to_wall"] or 0))
            for o in out:
                o["pick"] = o is best
        return out

    @staticmethod
    def embed_module():
        import importlib.util
        spec = importlib.util.spec_from_file_location("taste_embed", os.path.join(HERE, "taste-embed.py"))
        te = importlib.util.module_from_spec(spec); spec.loader.exec_module(te)
        return te

    def _embedder(self):
        if self._clip is None:
            te = self.embed_module()
            m, pre = te.model()
            self._clip = (te, m, pre)
        return self._clip

    def embed(self, paths):
        te, m, pre = self._embedder()
        return te.embed_files(m, pre, paths)

    def score_paths(self, paths, domain="flux", wall=True):
        ok, V = self.embed(paths)
        W = None
        if wall:
            wf = [f for f in glob.glob(os.path.join(WALL, "wall_*.png")) if "-init" not in f]
            _, W = self.embed(wf) if wf else ([], None)
        return self.score_vecs(V, domain, W, files=ok) if V is not None else []

def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # PC console is cp1252
    except Exception:
        pass
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "train":
        return train()
    if cmd == "prospective":
        # The cleanest test there is: a FROZEN judge scored only on renders made after it was
        # built. taste_judge.py prospective --data DIR [--model judge-v1.npz] [--seen auto]
        j = Judge.load(arg("--model"))
        data = arg("--data", HERE)
        cut = j.metrics["built"][:10].replace("-", "")
        down, insp, pairs, why = load_events(os.path.join(data, "events.jsonl") if os.path.exists(os.path.join(data, "events.jsonl")) else EVENTS)
        fav = listdir_ids(data, "favorites.txt", FAVS, "muse-")
        ids, X = load_npz(os.path.join(data, "render-embeds.npz"))
        knobs = knob_rows(os.path.join(data, "render-scores.csv"))
        new = np.array([i[:8] > cut for i in ids]) & ~np.array([knobs.get(i, {}).get("prompt_from") == "favorite replay" for i in ids])
        if arg("--seen") == "auto":
            sys.path.insert(0, os.path.expanduser("~/.dotfiles/bin"))
            import muse_presence as MP
            sf = MP.seen_flags(list(knobs.values()))
            new &= np.array([bool(sf.get(i)) or i in fav for i in ids])
        pos = np.array([i in fav for i in ids])
        L = j.logits(X)
        a = auc(L[new & pos], L[new & ~pos])
        print(json.dumps({"model": j.metrics["version"], "after": cut, "renders": int(new.sum()),
                          "stars": int((new & pos).sum()), "auc": None if a is None else round(a, 3),
                          "verdict": "need >= 15 new stars" if (new & pos).sum() < 15 else
                          ("clears" if a >= STEER_AUC else "below") + f" the {STEER_AUC} bar"}))
        return 0
    if cmd == "info":
        print(json.dumps({k: v for k, v in Judge.load(arg("--model")).metrics.items() if k not in ("results", "studio")}, indent=1))
        return 0
    if cmd == "score":
        skip = {"--domain", "--model"}
        files, k = [], 2
        while k < len(sys.argv):
            if sys.argv[k] in skip:
                k += 2; continue
            if sys.argv[k] != "--no-wall":
                files.append(sys.argv[k])
            k += 1
        try:
            import ctypes
            ctypes.windll.kernel32.SetPriorityClass(ctypes.windll.kernel32.GetCurrentProcess(), 0x40)  # IDLE
        except Exception:
            pass
        j = Judge.load(arg("--model"))
        if os.name == "nt" and Judge.embed_module().gaming():
            print(json.dumps({"error": "game running - not scoring"})); return 3
        print(json.dumps(j.score_paths(files, arg("--domain", "flux"), wall="--no-wall" not in sys.argv)))
        return 0
    print(__doc__)
    return 2

if __name__ == "__main__":
    sys.exit(main())
