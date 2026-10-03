/* kit.js — shared helpers for the computah screens (wall.html, ops.html, taste.html,
   NET-RUNNER via a vendored copy). Served from C:\dev\computah\farm\sd\kit.js (:7861/kit.js).
   Source of truth: ~/.dotfiles/computah/kit.js. Pair: kit.css (read its RULES first).
   Plain script, no modules: exposes window.KIT. ASCII-safe except the glyph table. */
(function () {
  const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  // fetch with cache-busting; kind = 'json' | 'text'. Returns null on any failure.
  async function get(path, kind = 'json') {
    try {
      const r = await fetch(`${path}${path.includes('?') ? '&' : '?'}t=${Date.now()}`, { cache: 'no-store' });
      return r.ok ? (kind === 'text' ? r.text() : r.json()) : null;
    } catch (e) { return null; }
  }

  // time
  const mins = ts => (Date.now() - new Date(ts).getTime()) / 60000;
  const ago = ts => { const m = mins(ts);
    return m < 1 ? 'now' : m < 60 ? Math.round(m) + 'm' : m < 1440 ? (m / 60).toFixed(m < 600 ? 1 : 0) + 'h' : Math.round(m / 1440) + 'd'; };
  const hhmm = ts => { const d = new Date(ts); return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0'); };
  const stale = (ts, seconds) => !ts || (Date.now() - new Date(ts).getTime()) / 1000 > seconds;
  const agoText = ts => { const a = ago(ts); return a === 'now' ? 'now' : a + ' ago'; };
  // clock time, with a weekday prefix when it isn't today ("12:41" vs "Fri 22:41"): tapes
  // listing today 12:41 above yesterday 22:41 read like a sort bug without it
  const when = ts => { const d = new Date(ts), now = new Date();
    return (d.toDateString() === now.toDateString() ? '' : d.toLocaleDateString(undefined, { weekday: 'short' }) + ' ') + hhmm(ts); };
  // CSS token -> literal value, for SVG/canvas attributes that can't take var()
  const cssvar = name => getComputedStyle(document.documentElement).getPropertyValue(name.startsWith('--') ? name : '--' + name).trim();
  // fixed-length rolling series for live sparklines: h = history(60); h.push(v); h.values
  const history = (n, fill = null) => { const values = Array(n).fill(fill);
    return { values, push(v) { values.push(v); values.shift(); }, get last() { return values[values.length - 1]; } }; };
  const pct = (a, b) => b ? Math.round(100 * a / b) + '%' : '—';

  // THE source-family mapping (one place; the wall, ops, taste all use it)
  const FAMILY = src => { const s = String(src || 'pure').split('+')[0];
    return s === 'pure' ? 'text' : (s === 'ref' || s === 'bestof') ? 'taste' : 'seeded'; };
  const FCOL = { text: 'var(--fam-text)', seeded: 'var(--fam-seeded)', taste: 'var(--fam-taste)' };
  const FHEX = { text: '#ff4d8d', seeded: '#7bf0f9', taste: '#ffffff' };      // for SVG/canvas fills
  const FGLYPH = { text: '○', seeded: '◇', taste: '◆' };
  const SRCN = { pure: 'text', screen: 'screen', crop: 'crop', feedback: 'past cell', 'feedback-inv': 'past inv',
                 game: 'game', 'game-inv': 'game inv', arena: 'are.na', cloud: 'cloud', fuji: 'fuji', taste: 'ej photo',
                 ref: '★ ref', bestof: 'best-of', bench: 'chart', studio: 'studio' };
  const srcName = src => { const s = String(src || 'pure').split('+')[0]; return SRCN[s] || s; };
  // a source label in its family color (the ONLY way source should be colored)
  const famSpan = (src, label) => { const f = FAMILY(src);
    return `<span class="fam-${f}">${esc(label != null ? label : srcName(src))}</span>`; };

  // bars: diverging log2 (weights ×0.5..×2: boosted solid, damped hollow) and linear 0..1
  const bar = w => { const l = Math.max(-1, Math.min(1, Math.log2(w))), p = Math.abs(l) * 50;
    return `<div class="kbar div"><i class="${l >= 0 ? 'pos' : 'neg'}" style="${l >= 0 ? 'left:50%' : 'right:50%'};width:${p}%"></i></div>`; };
  // linear bar 0..1; optional tick (0..1) marks a threshold, e.g. AUC ≥ 0.65
  const lin = (frac, color, tick) => `<div class="kbar"><i class="pos" style="left:0;width:${Math.max(0, Math.min(1, frac)) * 100}%${color ? ';background:' + color : ''}"></i>` +
    (tick != null ? `<b class="tick" style="left:${Math.max(0, Math.min(1, tick)) * 100}%"></b>` : '') + `</div>`;

  // sparkline: values -> inline SVG bars (or line). opts: {h, color, stack:[{values,color}], line:true}
  function spark(values, opts = {}) {
    // nulls (an un-filled KIT.history) draw NOTHING — no fake zeros — and keep their slot,
    // so the newest sample stays at the right edge from the first sample on
    const n = values.length || 1, W = 100, H = 30;
    const stacks = opts.stack || [{ values, color: opts.color || '#a9a9b0' }];
    const tot = Array.from({ length: n }, (_, i) => stacks.reduce((a, s) => a + (s.values[i] || 0), 0));
    const max = opts.max || Math.max(1e-9, ...tot), w = W / n;
    if (opts.line) {
      const pts = values.map((v, i) => v == null ? null : `${(i + .5) * w},${H - 1 - (H - 2) * (v / max)}`).filter(Boolean).join(' ');
      return `<svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" style="display:block;width:100%;height:${opts.h || '2.6em'}">` +
        `<polyline points="${pts}" fill="none" stroke="${opts.color || '#a9a9b0'}" stroke-width="1" vector-effect="non-scaling-stroke"/></svg>`;
    }
    let out = '';
    for (let i = 0; i < n; i++) {
      let y = H;
      if (!tot[i]) { out += `<rect x="${i * w + .15}" y="${H - .6}" width="${Math.max(.1, w - .3)}" height=".6" fill="#1f1f24"/>`; continue; }
      for (const s of stacks) { const v = s.values[i] || 0; if (!v) continue;
        const h = (H - 1) * v / max; y -= h;
        out += `<rect x="${i * w + .15}" y="${y}" width="${Math.max(.1, w - .3)}" height="${h}" fill="${s.color}"/>`; }
    }
    return `<svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" style="display:block;width:100%;height:${opts.h || '2.6em'}">${out}</svg>`;
  }

  // spark with a direct label strip: max on the left, last value on the right
  const sparkLabeled = (values, opts = {}) => { const vs = values.filter(v => v != null);
    const fmt = opts.fmt || (v => String(Math.round(v)));
    return `<div class="kspark">${spark(values, opts)}<div class="kspark-l"><span>max ${vs.length ? fmt(Math.max(...vs)) : '—'}</span>` +
      `<span class="hi">${vs.length ? fmt(vs[vs.length - 1]) : '—'}</span></div></div>`; };

  window.KIT = { esc, get, mins, ago, agoText, when, hhmm, stale, pct, cssvar, history,
                 FAMILY, FCOL, FHEX, FGLYPH, SRCN, srcName, famSpan, bar, lin, spark, sparkLabeled };
})();
