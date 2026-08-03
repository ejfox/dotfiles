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

#[derive(Debug, Deserialize, Default)]
pub struct Meta {
    #[serde(default = "default_title")]
    pub title: String,
}

fn default_title() -> String {
    "ejfox cheatsheet".into()
}

#[derive(Debug, Deserialize)]
pub struct Section {
    #[serde(default)]
    pub tone: String, // "" | accent | primary | gold | prose
    #[serde(default = "default_tool")]
    pub tool: String, // nvim | lazygit | both
    #[serde(default)]
    pub badge: String, // "" | nvim | lazygit
    pub title: String,
    #[serde(default)]
    pub open: bool,
    #[serde(default)]
    pub body: Vec<Item>,
}

fn default_tool() -> String {
    "both".into()
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
