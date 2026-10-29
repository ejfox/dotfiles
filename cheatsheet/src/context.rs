//! App context: cards that declare `apps = [...]` jump to the top (opened)
//! while one of those Mac apps is frontmost or running.
//!
//! The frontmost app comes from $CHEAT_FRONT, which the Hammerspoon panel sets
//! to the app you were in when you hit ⌥Space ?. "Running" is checked here with
//! `pgrep -x`, only for app names some card actually declares.

use std::process::Command;

use crate::model::Sheet;

fn is_running(app: &str) -> bool {
    Command::new("/usr/bin/pgrep")
        .args(["-xq", app])
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

/// Context apps in priority order: frontmost first, then any other running.
fn context_apps(sheet: &Sheet) -> Vec<String> {
    let mut declared: Vec<String> = Vec::new();
    for s in &sheet.sections {
        for a in &s.apps {
            if !declared.contains(a) {
                declared.push(a.clone());
            }
        }
    }
    let mut ctx = Vec::new();
    if let Ok(front) = std::env::var("CHEAT_FRONT") {
        if declared.contains(&front) {
            ctx.push(front);
        }
    }
    for a in declared {
        if !ctx.contains(&a) && is_running(&a) {
            ctx.push(a);
        }
    }
    ctx
}

/// Move live cards to the top (frontmost app's first), open them and tag them.
/// Every other card keeps its TOML order.
pub fn arrange(sheet: &mut Sheet) {
    let ctx = context_apps(sheet);
    if ctx.is_empty() {
        return;
    }
    for s in &mut sheet.sections {
        s.live = ctx.iter().find(|a| s.apps.contains(a)).cloned();
        if s.live.is_some() {
            s.open = true;
        }
    }
    let rank = |live: &Option<String>| match live {
        Some(app) => ctx.iter().position(|a| a == app).unwrap_or(usize::MAX),
        None => usize::MAX,
    };
    sheet.sections.sort_by_key(|s| rank(&s.live)); // stable: the rest keep their order
}
