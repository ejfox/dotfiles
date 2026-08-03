//! Render the cards to HTML and splice them into the chrome template so the
//! Hammerspoon floating panel is driven by cheatsheet.toml.

use crate::inline::{self, Seg};
use crate::model::{Item, Section, Sheet};

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

fn section_html(s: &Section) -> String {
    let class = if s.tone.is_empty() {
        String::new()
    } else {
        format!(" class=\"{}\"", s.tone)
    };
    let open = if s.open { " open" } else { "" };
    let summary = if s.badge.is_empty() {
        esc(&s.title)
    } else {
        format!(
            "<span class=\"badge {}\">{}</span> {}",
            s.badge,
            s.badge,
            esc(&s.title)
        )
    };

    let mut out = String::new();
    out.push_str(&format!(
        "<details{class}{open} data-tool=\"{}\">\n",
        s.tool
    ));
    out.push_str(&format!("  <summary>{summary}</summary>\n"));
    out.push_str("  <div class=\"c\">\n");

    for item in &s.body {
        match item {
            Item::Binding { k, d, hl } => {
                let cls = if *hl { "r dd" } else { "r" };
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

/// The cards region only (all sections, blank-line separated).
pub fn cards(sheet: &Sheet) -> String {
    sheet
        .sections
        .iter()
        .map(section_html)
        .collect::<Vec<_>>()
        .join("\n")
}

/// Full page: template chrome with {{CARDS}} replaced.
pub fn page(sheet: &Sheet, template: &str) -> String {
    template.replace("{{CARDS}}", &cards(sheet))
}
