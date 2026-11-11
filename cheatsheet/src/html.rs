//! Render the cards to HTML and splice them into the chrome template so the
//! Hammerspoon floating panel is driven by cheatsheet.toml.

use crate::inline::{self, Seg};
use crate::model::{Item, Section, Sheet};

/// Keys longer than this (shell commands, mostly) get a stacked row: the key
/// on its own line, the description under it. Short keys stay in two columns.
const STACK_AT: usize = 16;
/// A key longer than this reads as a command rather than a keystroke.
const COMMAND_KEY: usize = 10;

fn esc(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}

fn segs_html(s: &str) -> String {
    inline::parse(s)
        .iter()
        .map(|seg| match seg {
            Seg::Text(t) => esc(t),
            Seg::Kbd(t) => format!("<kbd>{}</kbd>", esc(t)),
            Seg::Em(t) => format!("<em>{}</em>", esc(t)),
            Seg::Bold(t) => format!("<b>{}</b>", esc(t)),
        })
        .collect()
}

fn row_class(k: &str, hl: bool) -> String {
    let mut cls = String::from("r");
    if hl {
        cls.push_str(" dd");
    }
    if k.chars().count() > STACK_AT {
        cls.push_str(" st");
    }
    cls
}

/// A card whose keys are mostly shell commands ("computah doctor", "desk
/// review") stacks every row, so the whole card reads as one uniform list
/// instead of a ragged mix of two-column and stacked rows.
fn is_command_card(s: &Section) -> bool {
    let lens: Vec<usize> = s
        .body
        .iter()
        .filter_map(|it| match it {
            Item::Binding { k, .. } => Some(k.chars().count()),
            _ => None,
        })
        .collect();
    let long = lens.iter().filter(|n| **n > COMMAND_KEY).count();
    !lens.is_empty() && long * 2 > lens.len()
}

fn section_html(s: &Section) -> String {
    let mut classes: Vec<&str> = Vec::new();
    if !s.tone.is_empty() {
        classes.push(&s.tone);
    }
    if is_command_card(s) {
        classes.push("stk");
    }
    let class = if classes.is_empty() {
        String::new()
    } else {
        format!(" class=\"{}\"", classes.join(" "))
    };
    // data-open is the card's resting state; the panel script applies it per
    // tab (the "all" tab is a closed outline).
    let open = if s.open { " open data-open=\"1\"" } else { "" };
    let mut summary = esc(&s.title);
    let mut live = "";
    if let Some(app) = &s.live {
        summary = format!("<span class=\"badge live\">● {}</span> {summary}", esc(app));
        live = " data-live=\"1\"";
    }

    let mut out = String::new();
    out.push_str(&format!(
        "<details{class}{open}{live} data-group=\"{}\">\n",
        esc(&s.group)
    ));
    out.push_str(&format!("  <summary>{summary}</summary>\n"));
    out.push_str("  <div class=\"c\">\n");

    for item in &s.body {
        match item {
            Item::Binding { k, d, hl } => {
                let cls = row_class(k, *hl);
                let desc = d
                    .as_ref()
                    .map(|d| format!("<span class=\"d\">{}</span>", esc(d)))
                    .unwrap_or_default();
                out.push_str(&format!(
                    "    <div class=\"{cls}\"><kbd>{}</kbd>{desc}</div>\n",
                    esc(k)
                ));
            }
            Item::KeylessDesc { d } => {
                out.push_str(&format!(
                    "    <div class=\"r\"><span class=\"d\">{}</span></div>\n",
                    esc(d)
                ));
            }
            Item::Div { .. } => out.push_str("    <div class=\"div\"></div>\n"),
            Item::Note { n } => {
                out.push_str(&format!("    <div class=\"n\">{}</div>\n", segs_html(n)))
            }
            Item::Foot { o } => {
                out.push_str(&format!("    <div class=\"o\">{}</div>\n", segs_html(o)))
            }
            Item::Label { lbl } => {
                out.push_str(&format!("    <div class=\"lbl\">{}</div>\n", esc(lbl)))
            }
            Item::Strat { strat, steps } => {
                out.push_str("    <div class=\"strat\">\n");
                out.push_str(&format!(
                    "      <span class=\"h\">{}</span>\n",
                    esc(strat)
                ));
                for step in steps {
                    out.push_str(&format!(
                        "      <span class=\"step\">{}</span>\n",
                        segs_html(step)
                    ));
                }
                out.push_str("    </div>\n");
            }
        }
    }

    out.push_str("  </div>\n");
    out.push_str("</details>\n");
    out
}

/// The cards region: every section, with a group heading before the first card
/// of each group (the headings only show on the "all" tab).
pub fn cards(sheet: &Sheet) -> String {
    let mut out = String::new();
    let mut last_group: Option<&str> = None;
    for s in &sheet.sections {
        if s.live.is_none() && last_group != Some(s.group.as_str()) {
            out.push_str(&format!(
                "<h2 class=\"g\" data-group=\"{0}\">{0}</h2>\n",
                esc(&s.group)
            ));
            last_group = Some(s.group.as_str());
        }
        out.push_str(&section_html(s));
        out.push('\n');
    }
    out
}

/// The tab strip: one button per group, then "all". Number keys match order.
pub fn tabs(sheet: &Sheet) -> String {
    sheet
        .meta
        .tabs()
        .iter()
        .enumerate()
        .map(|(i, g)| {
            format!(
                "<button data-tab=\"{0}\" title=\"key {1}\">{0}</button>",
                esc(g),
                i + 1
            )
        })
        .collect::<Vec<_>>()
        .join("\n    ")
}

/// Full page: template chrome with {{TABS}} and {{CARDS}} replaced.
pub fn page(sheet: &Sheet, template: &str) -> String {
    template
        .replace("{{TABS}}", &tabs(sheet))
        .replace("{{CARDS}}", &cards(sheet))
}
