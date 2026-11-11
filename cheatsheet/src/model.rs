//! Data model for the cheatsheet — deserialized straight from cheatsheet.toml.
//! This is the single source of truth shared by the TUI and the HTML generator.

use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct Sheet {
    #[serde(default)]
    pub meta: Meta,
    #[serde(default, rename = "section")]
    pub sections: Vec<Section>,
}

#[derive(Debug, Deserialize)]
pub struct Meta {
    #[serde(default = "default_title")]
    pub title: String,
    /// Tab order. Each section's `group` should be one of these; the panel and
    /// the TUI show one group at a time (plus "all").
    #[serde(default)]
    pub groups: Vec<String>,
}

fn default_title() -> String {
    "ejfox cheatsheet".into()
}

impl Default for Meta {
    fn default() -> Self {
        Meta {
            title: default_title(),
            groups: Vec::new(),
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct Section {
    #[serde(default)]
    pub tone: String, // "" | accent | primary | gold | prose
    /// Which tab the card lives under (one of meta.groups).
    #[serde(default)]
    pub group: String,
    pub title: String,
    #[serde(default)]
    pub open: bool,
    /// Mac app names ("Final Cut Pro", "Logic Pro"). While one is frontmost or
    /// running, the card jumps to the top, opened. See context.rs.
    #[serde(default)]
    pub apps: Vec<String>,
    /// Set at runtime by context::arrange: the app that made this card live.
    #[serde(skip)]
    pub live: Option<String>,
    #[serde(default)]
    pub body: Vec<Item>,
}

impl Meta {
    /// Tab names in order, always ending in "all".
    pub fn tabs(&self) -> Vec<String> {
        let mut tabs = self.groups.clone();
        tabs.push("all".into());
        tabs
    }
}

/// One line inside a card. Untagged: the present keys decide the variant, so
/// TOML stays terse and hand-editable. Order matters — most specific first.
#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum Item {
    Strat {
        strat: String,
        #[serde(default)]
        steps: Vec<String>,
    },
    Div {
        div: bool,
    },
    Label {
        lbl: String,
    },
    Note {
        n: String,
    },
    Foot {
        o: String,
    },
    Binding {
        k: String,
        #[serde(default)]
        d: Option<String>,
        #[serde(default)]
        hl: bool,
    },
    KeylessDesc {
        d: String,
    },
}
