#!/usr/local/bin/python3
"""ViPer-style taste rubric: EJ's one-line "why" notes + the images → structured
liked / disliked visual attributes, aggregated into one rubric JSON. Runs on the Mac.

  taste-rubric                         pull events.jsonl from computah, extract every new
                                       why-note, write ~/.cache/muse/taste-rubric.json
  taste-rubric --events F --out F      any events file → any rubric file (tests/fixtures)
  taste-rubric --backend qwen          use the PC's local Qwen (:8085, text only — it never
                                       sees the image). Only if it is ALREADY up: this script
                                       never starts it (it evicts FLUX from the GPU).
  taste-rubric --dry                   show what would be extracted, no LLM calls

why event (wall.html → preview-server.ps1, 2026-10-06):
  {"type":"why","id":..., "kind":"flux"|"studio", "verdict":"star"|"down"|"pair",
   "text":"...", "lose":... (pair only: the image that lost)}

Per note the LLM gets the image (claude backend: it Reads a 1024px copy), the render's
prompt/style from its trace, the verdict and EJ's words, and returns
  {"liked":[{"attribute","category","evidence"}], "disliked":[...]}
category ∈ color · composition · subject · medium · texture · light · mood · detail · text.
Rule: only attributes grounded in his words (the image just disambiguates them) — the
model must not invent taste he didn't express. Results are cached per note.
Aggregate: attribute → liked n / disliked n / net / example ids. Nothing reads the
rubric yet (no steering); it is a scaffold for later prompt-building + judge features.
"""
import hashlib, json, os, re, subprocess, sys, time, urllib.request

E = os.environ.get
C = os.path.expanduser("~/.cache/muse")
IMG = f"{C}/rubric-img"
MODEL = E("RUBRIC_MODEL", "claude-sonnet-5")
QWEN = E("RUBRIC_QWEN", "http://10.0.0.169:8085/v1")
PC_EVENTS = "C:/dev/computah/farm/sd/taste/events.jsonl"
PC_GALLERY = "C:/dev/computah/renders/muse-gallery"
PC_STUDIO = "C:/dev/computah/renders/mathblend/masterpieces"
CATS = ["color", "composition", "subject", "medium", "texture", "light", "mood", "detail", "text"]

def arg(flag, default=None):
    return sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else default

def host():
    lan = subprocess.run(["nc", "-z", "-G", "2", "10.0.0.169", "22"], capture_output=True).returncode == 0
    return "ejfox@10.0.0.169" if lan else "computah"

def fetch(note):
    """Local 1024px jpg of the note's image + its trace (prompt/style). Cached."""
    os.makedirs(IMG, exist_ok=True)
    i, kind = note["id"], note.get("kind") or ("flux" if re.match(r"^\d{8}-\d{6}-c\d+$", note["id"]) else "studio")
    stem = f"muse-{i}" if kind == "flux" else i
    src = PC_GALLERY if kind == "flux" else PC_STUDIO
    jpg, js = f"{IMG}/{stem}.jpg", f"{IMG}/{stem}.json"
    if not os.path.exists(jpg):
        png = f"{IMG}/{stem}.png"
        h = host()
        subprocess.run(["scp", "-q", f"{h}:{src}/{stem}.png", png], capture_output=True)
        subprocess.run(["scp", "-q", f"{h}:{src}/{stem}.json", js], capture_output=True)
        if os.path.exists(png):
            subprocess.run(["sips", "-Z", "1024", "-s", "format", "jpeg", png, "--out", jpg], capture_output=True)
            os.remove(png)
    trace = {}
    try:
        trace = json.load(open(js, encoding="utf-8"))
    except (OSError, ValueError):
        pass
    desc = trace.get("prompt") or trace.get("prompt_subject") or ""
    if kind == "studio":
        desc = ", ".join(f"{k}={trace[k]}" for k in ("scene", "signal", "dither", "glass", "atmos") if k in trace) or i
    return (jpg if os.path.exists(jpg) else None), desc[:600], kind

PROMPT = """You are extracting EJ's visual taste from one short note he typed about an image.

Verdict: {verdict_text}
EJ's note: "{text}"
How the image was made: {desc}
{image_line}

Return ONLY a JSON object, no prose, no code fence:
{{"liked":[{{"attribute":"...","category":"...","evidence":"..."}}],
  "disliked":[{{"attribute":"...","category":"...","evidence":"..."}}]}}

Rules:
- attribute = a short reusable visual property (2-5 words, lowercase), e.g. "hard black shadows",
  "pastel palette", "centered single subject", "visible brush texture". Not a whole description.
- category is one of: {cats}.
- ONLY attributes grounded in EJ's words. Use the image (and how it was made) only to make
  his words concrete (e.g. "the colors" → which colors). Do not add taste he did not express.
- evidence = the words of his note that support it.
- {polarity}
- 0-4 attributes per list. Empty lists are fine."""

def verdict_text(n):
    v = n.get("verdict")
    if v == "star":
        return "he STARRED this image (liked it)", "His note explains what he liked; dislikes only if he names a flaw."
    if v == "down":
        return "he gave it THUMBS-DOWN (disliked it)", "His note explains what he disliked; likes only if he names a redeeming part."
    return ("he picked this image over another one in a pair",
            "Liked = what made it win; disliked = what he says the losing image had or lacked.")

def ask_claude(prompt, img):
    cwd = os.path.dirname(img) if img else "/tmp"
    if img:
        prompt += f"\n\nFirst Read the image file {os.path.basename(img)} in the current directory and look at it."
    r = subprocess.run(["claude", "-p", prompt, "--model", MODEL, "--allowedTools", "Read",
                        "--output-format", "text"], capture_output=True, text=True, cwd=cwd, timeout=240)
    return r.stdout

def ask_qwen(prompt):
    body = json.dumps({"model": "qwen", "max_tokens": 900, "temperature": 0.2,
                       "messages": [{"role": "user", "content": prompt + "\n/no_think"}]}).encode()
    req = urllib.request.Request(f"{QWEN}/chat/completions", body, {"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as f:
        return json.load(f)["choices"][0]["message"]["content"]

def qwen_up():
    try:
        with urllib.request.urlopen(f"{QWEN}/models", timeout=4) as f:
            return f.status == 200
    except Exception:
        return False

def parse(out):
    out = re.sub(r"<think>.*?</think>", "", out or "", flags=re.S)
    m = re.search(r"\{.*\}", out, re.S)
    if not m:
        return None
    try:
        d = json.loads(m.group(0))
    except ValueError:
        return None
    clean = {}
    for side in ("liked", "disliked"):
        xs = []
        for a in d.get(side) or []:
            if isinstance(a, dict) and a.get("attribute"):
                cat = str(a.get("category", "")).lower().strip()
                xs.append({"attribute": str(a["attribute"]).lower().strip()[:60],
                           "category": cat if cat in CATS else "other",
                           "evidence": str(a.get("evidence", ""))[:160]})
        clean[side] = xs[:4]
    return clean

def note_key(n):
    return hashlib.sha1(json.dumps([n.get("id"), n.get("verdict"), n.get("text"), n.get("lose")]).encode()).hexdigest()[:16]

def main():
    backend = arg("--backend", "claude")
    events = arg("--events")
    out = arg("--out", f"{C}/taste-rubric.json")
    real_out = os.path.realpath(out) == os.path.realpath(f"{C}/taste-rubric.json")
    if not events:
        events = f"{C}/events-pc.jsonl"
        subprocess.run(["scp", "-q", f"{host()}:{PC_EVENTS}", events], check=True)
    notes = []
    for line in open(events, encoding="utf-8"):
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if e.get("type") == "why" and e.get("id") and (e.get("text") or "").strip():
            notes.append(e)
    if any(n.get("fixture") for n in notes) and real_out:
        sys.exit("✗ fixture notes must never go into the real rubric — pass --out somewhere else")
    cache_path = out[:-5] + "-cache.json"
    cache = json.load(open(cache_path)) if os.path.exists(cache_path) else {}
    print(f"◆ {len(notes)} why-notes · {sum(note_key(n) in cache for n in notes)} cached · backend {backend}")
    if backend == "qwen" and not qwen_up() and not "--dry" in sys.argv:
        sys.exit("✗ Qwen :8085 is not up — this script never starts it (it evicts FLUX). Use the claude backend.")
    for n in notes:
        k = note_key(n)
        if k in cache:
            continue
        img, desc, kind = fetch(n)
        vt, pol = verdict_text(n)
        prompt = PROMPT.format(verdict_text=vt, text=n["text"].replace('"', "'"), desc=desc or "(unknown)",
                               cats=", ".join(CATS), polarity=pol,
                               image_line="" if (backend == "qwen" or not img) else "The image is attached as a file (see below).")
        if "--dry" in sys.argv:
            print(f"  · {n['id']} [{n.get('verdict')}] “{n['text']}” img={'yes' if img else 'no'}"); continue
        raw = ask_qwen(prompt) if backend == "qwen" else ask_claude(prompt, img if backend == "claude" else None)
        res = parse(raw)
        if res is None:
            print(f"  ✗ {n['id']}: unparseable reply, skipped ({(raw or '')[:80]!r})"); continue
        cache[k] = {"id": n["id"], "kind": kind, "verdict": n.get("verdict"), "text": n["text"], "lose": n.get("lose"),
                    "ts": n.get("ts"), "backend": backend, **res}
        print(f"  ◆ {n['id']} [{n.get('verdict')}] +{[a['attribute'] for a in res['liked']]} −{[a['attribute'] for a in res['disliked']]}")
        json.dump(cache, open(cache_path, "w"), indent=1)
    if "--dry" in sys.argv:
        return 0
    agg = {}
    for k, r in cache.items():
        for side, sign in (("liked", 1), ("disliked", -1)):
            for a in r.get(side, []):
                g = agg.setdefault(a["attribute"], {"attribute": a["attribute"], "category": a["category"],
                                                    "liked": 0, "disliked": 0, "ids": [], "evidence": []})
                g["liked" if sign > 0 else "disliked"] += 1
                if r["id"] not in g["ids"]:
                    g["ids"].append(r["id"])
                if a["evidence"] and len(g["evidence"]) < 3:
                    g["evidence"].append(a["evidence"])
    attrs = sorted(agg.values(), key=lambda g: (-(g["liked"] - g["disliked"]), -g["liked"]))
    for g in attrs:
        g["net"] = g["liked"] - g["disliked"]
    rub = {"built": time.strftime("%Y-%m-%d %H:%M"), "notes": len(cache),
           "by_category": {c: [g["attribute"] for g in attrs if g["category"] == c] for c in CATS + ["other"]},
           "attributes": attrs}
    json.dump(rub, open(out, "w"), indent=1)
    print(f"◆ rubric: {len(attrs)} attributes from {len(cache)} notes → {out}")
    for g in attrs[:6]:
        print(f"   {g['net']:+d}  {g['attribute']}  ({g['category']}; ♥{g['liked']} ✗{g['disliked']})")
    return 0

if __name__ == "__main__":
    sys.exit(main())
