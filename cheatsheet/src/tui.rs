//! The terminal cheatsheet — a reader-focused, scrollable, searchable view of
//! the same cheatsheet.toml that drives the Hammerspoon panel.

use std::io::{self, Stdout};
use std::time::Duration;

use crossterm::event::{
    self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers,
};
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use crossterm::{execute, cursor};
use ratatui::prelude::*;
use ratatui::widgets::Paragraph;

use crate::inline::{self, Seg};
use crate::model::{Item, Section, Sheet};

// ── vulpes palette ──────────────────────────────────────────────────────
const BASE: Color = Color::Rgb(255, 77, 141); // pink
const TEAL: Color = Color::Rgb(123, 240, 249);
const GOLD: Color = Color::Rgb(255, 212, 137);
const FG: Color = Color::Rgb(242, 207, 223);
const DESC: Color = Color::Rgb(170, 150, 165);
const HLDESC: Color = Color::Rgb(120, 205, 215);
const FAINT: Color = Color::Rgb(84, 72, 80);
const BADGE: Color = Color::Rgb(150, 120, 135);

const KEYCOL_MAX: usize = 18;
// masonry columns, mirroring the HTML panel: narrow columns keep the key→desc
// gap tight so right-aligned descriptions stay readable.
const COL_IDEAL: usize = 38; // preferred per-column content width
const COL_MIN: usize = 30;
const COL_MAX: usize = 48; // keep columns narrow so right-aligned descs stay tight
const COL_GAP: usize = 3;

/// Non-interactive render of the TUI content to plain text (for testing /
/// piping / previewing). Exercises the same build_lines path the TUI uses.
pub fn dump(sheet: &Sheet, width: usize, filter: &str, query: &str) -> String {
    compose(sheet, filter, query, width)
        .iter()
        .map(|line| {
            line.spans
                .iter()
                .map(|s| s.content.as_ref())
                .collect::<String>()
        })
        .collect::<Vec<_>>()
        .join("\n")
}

pub fn run(sheet: &Sheet) -> io::Result<()> {
    let mut term = setup()?;
    let res = App::new(sheet).run(&mut term);
    teardown(&mut term)?;
    res
}

fn setup() -> io::Result<Terminal<CrosstermBackend<Stdout>>> {
    enable_raw_mode()?;
    let mut out = io::stdout();
    execute!(out, EnterAlternateScreen, cursor::Hide)?;
    Terminal::new(CrosstermBackend::new(out))
}

fn teardown(term: &mut Terminal<CrosstermBackend<Stdout>>) -> io::Result<()> {
    disable_raw_mode()?;
    execute!(term.backend_mut(), LeaveAlternateScreen, cursor::Show)?;
    term.show_cursor()
}

struct App<'a> {
    sheet: &'a Sheet,
    filter: &'static str, // all | nvim | lazygit
    query: String,
    searching: bool,
    offset: usize,
    // cache
    lines: Vec<Line<'static>>,
    cache_key: (u16, &'static str, String),
}

impl<'a> App<'a> {
    fn new(sheet: &'a Sheet) -> Self {
        App {
            sheet,
            filter: "all",
            query: String::new(),
            searching: false,
            offset: 0,
            lines: Vec::new(),
            cache_key: (0, "", String::new()),
        }
    }

    fn run(&mut self, term: &mut Terminal<CrosstermBackend<Stdout>>) -> io::Result<()> {
        loop {
            term.draw(|f| self.draw(f))?;
            if !event::poll(Duration::from_millis(200))? {
                continue;
            }
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Release {
                    continue;
                }
                if self.handle(key) {
                    return Ok(());
                }
            }
        }
    }

    /// returns true to quit
    fn handle(&mut self, key: KeyEvent) -> bool {
        let ctrl = key.modifiers.contains(KeyModifiers::CONTROL);
        if self.searching {
            match key.code {
                KeyCode::Esc => {
                    self.query.clear();
                    self.searching = false;
                    self.offset = 0;
                }
                KeyCode::Enter => self.searching = false,
                KeyCode::Backspace => {
                    self.query.pop();
                    self.offset = 0;
                }
                KeyCode::Char(c) => {
                    self.query.push(c);
                    self.offset = 0;
                }
                _ => {}
            }
            return false;
        }

        match key.code {
            KeyCode::Char('q') | KeyCode::Esc => return true,
            KeyCode::Char('c') if ctrl => return true,
            KeyCode::Char('j') | KeyCode::Down => self.scroll(1),
            KeyCode::Char('k') | KeyCode::Up => self.scroll(-1),
            KeyCode::Char('d') if ctrl => self.scroll(10),
            KeyCode::Char('u') if ctrl => self.scroll(-10),
            KeyCode::Char(' ') | KeyCode::PageDown => self.scroll(20),
            KeyCode::Char('b') | KeyCode::PageUp => self.scroll(-20),
            KeyCode::Char('g') | KeyCode::Home => self.offset = 0,
            KeyCode::Char('G') | KeyCode::End => self.offset = usize::MAX,
            KeyCode::Char('/') => {
                self.searching = true;
                self.query.clear();
                self.offset = 0;
            }
            KeyCode::Char('a') => self.set_filter("all"),
            KeyCode::Char('n') => self.set_filter("nvim"),
            KeyCode::Char('l') => self.set_filter("lazygit"),
            _ => {}
        }
        false
    }

    fn set_filter(&mut self, f: &'static str) {
        self.filter = f;
        self.offset = 0;
    }

    fn scroll(&mut self, delta: i64) {
        let cur = self.offset as i64;
        self.offset = (cur + delta).max(0) as usize;
    }

    fn draw(&mut self, f: &mut Frame) {
        let area = f.area();
        let chunks = Layout::vertical([
            Constraint::Length(1), // title bar
            Constraint::Min(1),    // body
            Constraint::Length(1), // status
        ])
        .split(area);

        let body_w = chunks[1].width;
        let body_h = chunks[1].height as usize;

        self.ensure_lines(body_w);

        // clamp offset
        let max_off = self.lines.len().saturating_sub(body_h);
        if self.offset > max_off {
            self.offset = max_off;
        }

        // title bar
        let title = &self.sheet.meta.title;
        let bar = Line::from(vec![
            Span::styled(
                format!(" {} ", title),
                Style::default().fg(Color::Black).bg(BASE).bold(),
            ),
            Span::styled(
                format!("  nvim + lazygit  ·  teal = daily driver"),
                Style::default().fg(BADGE),
            ),
        ]);
        f.render_widget(Paragraph::new(bar), chunks[0]);

        // body slice
        let end = (self.offset + body_h).min(self.lines.len());
        let visible: Vec<Line> = self.lines[self.offset..end].to_vec();
        f.render_widget(Paragraph::new(visible), chunks[1]);

        // status bar
        let pct = if self.lines.len() <= body_h {
            100
        } else {
            (self.offset * 100) / max_off.max(1)
        };
        let status = if self.searching || !self.query.is_empty() {
            Line::from(vec![
                Span::styled(" /", Style::default().fg(TEAL).bold()),
                Span::styled(
                    format!("{}", self.query),
                    Style::default().fg(FG),
                ),
                Span::styled(
                    if self.searching { "▏" } else { "" },
                    Style::default().fg(TEAL),
                ),
                Span::styled(
                    "   esc clear · enter keep",
                    Style::default().fg(FAINT),
                ),
            ])
        } else {
            Line::from(vec![
                Span::styled(
                    format!(" {:>3}% ", pct),
                    Style::default().fg(Color::Black).bg(FAINT),
                ),
                Span::styled(
                    format!("  filter:{}", self.filter),
                    Style::default().fg(if self.filter == "all" { BADGE } else { TEAL }),
                ),
                Span::styled(
                    "   j/k scroll · / search · a/n/l filter · q quit",
                    Style::default().fg(FAINT),
                ),
            ])
        };
        f.render_widget(Paragraph::new(status), chunks[2]);
    }

    fn ensure_lines(&mut self, width: u16) {
        let key = (width, self.filter, self.query.clone());
        if key == self.cache_key && !self.lines.is_empty() {
            return;
        }
        self.lines = compose(self.sheet, self.filter, &self.query, width as usize);
        self.cache_key = key;
    }
}

// ── line building ───────────────────────────────────────────────────────

fn tool_visible(section: &Section, filter: &str) -> bool {
    filter == "all" || section.tool == filter || section.tool == "both"
}

fn kbd_color(tone: &str, hl: bool) -> Color {
    if hl {
        return TEAL;
    }
    match tone {
        "primary" => BASE,
        "accent" => TEAL,
        "gold" => GOLD,
        "prose" => DESC,
        _ => FG,
    }
}

fn title_color(tone: &str) -> Color {
    match tone {
        "primary" => BASE,
        "accent" => TEAL,
        "gold" => GOLD,
        _ => FG,
    }
}

/// Compose the full view: build each section as a block, pack the blocks into
/// balanced masonry columns, and stitch the columns side by side into lines.
fn compose(sheet: &Sheet, filter: &str, query: &str, total_width: usize) -> Vec<Line<'static>> {
    let total_width = total_width.max(24);
    let ncols = ((total_width + COL_GAP) / (COL_IDEAL + COL_GAP)).clamp(1, 4);
    let colw = ((total_width - COL_GAP * (ncols - 1)) / ncols).clamp(COL_MIN, COL_MAX);
    let cw = colw.saturating_sub(2).max(14); // inner width after the 2-col gutter
    let q = query.to_lowercase();

    let mut blocks: Vec<Vec<Line<'static>>> = Vec::new();
    for s in &sheet.sections {
        if !tool_visible(s, filter) {
            continue;
        }
        if !q.is_empty() && !section_matches(s, &q) {
            continue;
        }
        let mut b = build_block(s, cw, &q);
        b.push(Line::from("")); // gap between stacked blocks
        blocks.push(b);
    }
    if blocks.is_empty() {
        return vec![Line::from(Span::styled(
            "  no matches",
            Style::default().fg(FAINT),
        ))];
    }

    let cols = distribute(blocks, ncols);
    let maxlen = cols.iter().map(|c| c.len()).max().unwrap_or(0);
    let mut composed: Vec<Line<'static>> = Vec::with_capacity(maxlen);
    for r in 0..maxlen {
        let mut spans: Vec<Span<'static>> = Vec::new();
        for (i, col) in cols.iter().enumerate() {
            let last = i + 1 == cols.len();
            if i > 0 {
                spans.push(Span::raw(" ".repeat(COL_GAP)));
            }
            match col.get(r) {
                Some(line) => {
                    let w = line_width(line);
                    spans.extend(line.spans.iter().cloned());
                    if !last && w < colw {
                        spans.push(Span::raw(" ".repeat(colw - w)));
                    }
                }
                None => {
                    if !last {
                        spans.push(Span::raw(" ".repeat(colw)));
                    }
                }
            }
        }
        composed.push(Line::from(spans));
    }
    composed
}

/// Pack section blocks into `ncols` balanced columns, preserving order.
fn distribute(blocks: Vec<Vec<Line<'static>>>, ncols: usize) -> Vec<Vec<Line<'static>>> {
    if ncols <= 1 {
        return vec![blocks.into_iter().flatten().collect()];
    }
    let total: usize = blocks.iter().map(|b| b.len()).sum();
    let target = total.div_ceil(ncols);
    let mut cols: Vec<Vec<Line<'static>>> = vec![Vec::new(); ncols];
    let mut ci = 0;
    for b in blocks {
        // move to the next column once this one has (roughly) its share
        if ci + 1 < ncols && !cols[ci].is_empty() && cols[ci].len() + b.len() / 2 >= target {
            ci += 1;
        }
        cols[ci].extend(b);
    }
    cols
}

fn line_width(line: &Line) -> usize {
    line.spans.iter().map(|s| s.content.chars().count()).sum()
}

/// Build one section as a column block: header, then table rows / prose.
fn build_block(s: &Section, cw: usize, q: &str) -> Vec<Line<'static>> {
    let mut out: Vec<Line<'static>> = Vec::new();

    // header — colored bar, uppercase title, dim badge
    let tcol = title_color(&s.tone);
    let mut hspans = vec![
        Span::styled("▌ ", Style::default().fg(tcol)),
        Span::styled(s.title.to_uppercase(), Style::default().fg(tcol).bold()),
    ];
    if !s.badge.is_empty() {
        hspans.push(Span::styled(
            format!("  {}", s.badge),
            Style::default().fg(BADGE),
        ));
    }
    out.push(Line::from(hspans));

    // per-section key column width so keys share one left rail
    let kw = s
        .body
        .iter()
        .filter_map(|it| match it {
            Item::Binding { k, .. } => Some(k.chars().count()),
            _ => None,
        })
        .max()
        .unwrap_or(0)
        .min(KEYCOL_MAX);

    for item in &s.body {
        match item {
            Item::Binding { k, d, hl } => {
                if !q.is_empty() {
                    let hay = format!(
                        "{} {}",
                        k.to_lowercase(),
                        d.as_deref().unwrap_or("").to_lowercase()
                    );
                    if !hay.contains(q) && !s.title.to_lowercase().contains(q) {
                        continue;
                    }
                }
                push_binding(&mut out, k, d.as_deref(), *hl, &s.tone, kw, cw);
            }
            Item::KeylessDesc { d } => {
                for l in wrap_str(d, cw) {
                    let pad = cw.saturating_sub(l.chars().count());
                    out.push(Line::from(vec![
                        Span::raw(" ".repeat(2 + pad)),
                        Span::styled(l, Style::default().fg(DESC)),
                    ]));
                }
            }
            Item::Div { .. } => {
                if q.is_empty() {
                    push_blank(&mut out);
                }
            }
            Item::Label { lbl } => {
                push_blank(&mut out);
                out.push(Line::from(vec![
                    Span::raw("  "),
                    Span::styled(
                        lbl.to_uppercase(),
                        Style::default().fg(BASE).add_modifier(Modifier::DIM),
                    ),
                ]));
            }
            Item::Note { n } => push_prose(&mut out, n, 0, DESC, cw),
            Item::Foot { o } => push_foot(&mut out, o, cw),
            Item::Strat { strat, steps } => {
                push_blank(&mut out);
                out.push(Line::from(vec![
                    Span::raw("  "),
                    Span::styled(strat.to_uppercase(), Style::default().fg(TEAL).bold()),
                ]));
                for step in steps {
                    push_prose(&mut out, step, 2, DESC, cw);
                }
            }
        }
    }
    out
}

/// Push a blank line, but never two in a row — keeps a steady vertical rhythm.
fn push_blank(out: &mut Vec<Line<'static>>) {
    let last_blank = out
        .last()
        .map(|l| l.spans.iter().all(|s| s.content.trim().is_empty()))
        .unwrap_or(true);
    if !last_blank {
        out.push(Line::from(""));
    }
}

fn section_matches(s: &Section, q: &str) -> bool {
    if q.is_empty() {
        return true;
    }
    if s.title.to_lowercase().contains(q) {
        return true;
    }
    s.body.iter().any(|it| match it {
        Item::Binding { k, d, .. } => {
            k.to_lowercase().contains(q)
                || d.as_deref().unwrap_or("").to_lowercase().contains(q)
        }
        Item::KeylessDesc { d } => d.to_lowercase().contains(q),
        Item::Note { n } => n.to_lowercase().contains(q),
        Item::Foot { o } => o.to_lowercase().contains(q),
        Item::Label { lbl } => lbl.to_lowercase().contains(q),
        Item::Strat { strat, steps } => {
            strat.to_lowercase().contains(q)
                || steps.iter().any(|s| s.to_lowercase().contains(q))
        }
        Item::Div { .. } => false,
    })
}

fn push_binding(
    out: &mut Vec<Line<'static>>,
    k: &str,
    d: Option<&str>,
    hl: bool,
    tone: &str,
    kw: usize,
    cw: usize,
) {
    let kcol = kbd_color(tone, hl);
    let dcol = if hl { HLDESC } else { DESC };
    let key_disp = k.chars().count();

    // highlighted (daily-driver) rows get a teal change-bar in the left gutter;
    // everything else shares the same 2-col gutter so all keys line up.
    let gutter = if hl {
        Span::styled("▏ ", Style::default().fg(TEAL))
    } else {
        Span::raw("  ")
    };

    let desc = d.unwrap_or("");
    if desc.is_empty() {
        out.push(Line::from(vec![
            gutter,
            Span::styled(k.to_string(), Style::default().fg(kcol).bold()),
        ]));
        return;
    }

    // table logic: key on the left rail, description RIGHT-aligned to the column
    // edge, wrapping ragged-left — like the HTML panel's text-align:right.
    let gap_min = 2;
    let desc_field = cw.saturating_sub(kw + gap_min).max(6);
    let dlines = wrap_str(desc, desc_field);

    let first = dlines.first().cloned().unwrap_or_default();
    let mid = cw
        .saturating_sub(key_disp + first.chars().count())
        .max(gap_min);
    out.push(Line::from(vec![
        gutter,
        Span::styled(k.to_string(), Style::default().fg(kcol).bold()),
        Span::raw(" ".repeat(mid)),
        Span::styled(first, Style::default().fg(dcol)),
    ]));

    // continuation lines: right-aligned to the same edge (ragged left)
    for cont in dlines.iter().skip(1) {
        let pad = cw.saturating_sub(cont.chars().count());
        out.push(Line::from(vec![
            Span::raw(" ".repeat(2 + pad)),
            Span::styled(cont.clone(), Style::default().fg(dcol)),
        ]));
    }
}

fn push_foot(out: &mut Vec<Line<'static>>, text: &str, cw: usize) {
    let runs = segs_to_runs(text, DESC);
    let wrapped = wrap_runs(&runs, cw.saturating_sub(2));
    for (i, mut line) in wrapped.into_iter().enumerate() {
        let prefix = if i == 0 {
            Span::styled("  ↳ ", Style::default().fg(BASE).add_modifier(Modifier::DIM))
        } else {
            Span::raw("    ")
        };
        line.insert(0, prefix);
        out.push(Line::from(line));
    }
}

fn push_prose(out: &mut Vec<Line<'static>>, text: &str, sub: usize, base: Color, cw: usize) {
    let runs = segs_to_runs(text, base);
    let wrapped = wrap_runs(&runs, cw.saturating_sub(sub));
    for mut line in wrapped {
        line.insert(0, Span::raw(" ".repeat(2 + sub)));
        out.push(Line::from(line));
    }
}

/// Convert inline segments to styled runs for wrapping.
fn segs_to_runs(text: &str, base: Color) -> Vec<(Color, Modifier, String)> {
    inline::parse(text)
        .into_iter()
        .map(|seg| match seg {
            Seg::Text(t) => (base, Modifier::empty(), t),
            Seg::Kbd(t) => (TEAL, Modifier::empty(), t),
            Seg::Em(t) => (TEAL, Modifier::empty(), t),
            Seg::Bold(t) => (FG, Modifier::BOLD, t),
        })
        .collect()
}

/// Greedy word-wrap over styled runs. A "word" may span multiple style runs
/// (e.g. bold `R` + normal `eset)`), so we flatten to styled chars, split on
/// spaces, and never break inside a word — that keeps `**R**eset` intact.
fn wrap_runs(runs: &[(Color, Modifier, String)], width: usize) -> Vec<Vec<Span<'static>>> {
    let width = width.max(8);

    // 1. flatten runs into styled chars
    let mut chars: Vec<(char, Style)> = Vec::new();
    for (color, modi, text) in runs {
        let style = Style::default().fg(*color).add_modifier(*modi);
        for c in text.chars() {
            chars.push((c, style));
        }
    }

    // 2. split into words on spaces (runs of spaces collapse to one)
    let mut words: Vec<Vec<(char, Style)>> = Vec::new();
    let mut word: Vec<(char, Style)> = Vec::new();
    for (c, st) in chars {
        if c == ' ' {
            if !word.is_empty() {
                words.push(std::mem::take(&mut word));
            }
        } else {
            word.push((c, st));
        }
    }
    if !word.is_empty() {
        words.push(word);
    }

    // 3. greedily pack words into lines, coalescing same-style char runs
    let mut lines: Vec<Vec<Span<'static>>> = Vec::new();
    let mut cur: Vec<Span<'static>> = Vec::new();
    let mut col = 0usize;
    for w in &words {
        let wlen = w.len();
        if col > 0 && col + 1 + wlen > width {
            lines.push(std::mem::take(&mut cur));
            col = 0;
        }
        if col > 0 {
            cur.push(Span::raw(" "));
            col += 1;
        }
        cur.extend(coalesce(w));
        col += wlen;
    }
    if !cur.is_empty() {
        lines.push(cur);
    }
    if lines.is_empty() {
        lines.push(vec![Span::raw("")]);
    }
    lines
}

/// Merge consecutive equal-style chars into styled spans.
fn coalesce(word: &[(char, Style)]) -> Vec<Span<'static>> {
    let mut spans: Vec<Span<'static>> = Vec::new();
    let mut buf = String::new();
    let mut cur_style: Option<Style> = None;
    for (c, st) in word {
        if Some(*st) != cur_style {
            if let Some(s) = cur_style {
                spans.push(Span::styled(std::mem::take(&mut buf), s));
            }
            cur_style = Some(*st);
        }
        buf.push(*c);
    }
    if let Some(s) = cur_style {
        spans.push(Span::styled(buf, s));
    }
    spans
}

/// Plain greedy word-wrap.
fn wrap_str(s: &str, width: usize) -> Vec<String> {
    let width = width.max(8);
    let mut lines = Vec::new();
    let mut cur = String::new();
    for word in s.split(' ') {
        let wlen = word.chars().count();
        let clen = cur.chars().count();
        if clen + (if clen > 0 { 1 } else { 0 }) + wlen > width && clen > 0 {
            lines.push(std::mem::take(&mut cur));
            cur.push_str(word);
        } else {
            if !cur.is_empty() {
                cur.push(' ');
            }
            cur.push_str(word);
        }
    }
    if !cur.is_empty() {
        lines.push(cur);
    }
    if lines.is_empty() {
        lines.push(String::new());
    }
    lines
}
