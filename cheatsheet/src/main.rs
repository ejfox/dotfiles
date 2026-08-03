//! cheat — ejfox's cheatsheet, from one TOML source.
//!
//!   cheat            open the TUI (default)
//!   cheat gen [out]  regenerate the Hammerspoon HTML panel from the TOML
//!   cheat help

mod html;
mod inline;
mod model;
mod tui;

use std::path::PathBuf;
use std::process::ExitCode;

use model::Sheet;

fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").expect("HOME not set"))
}

fn dot() -> PathBuf {
    home().join(".dotfiles/cheatsheet")
}

fn toml_path() -> PathBuf {
    std::env::var("CHEAT_TOML")
        .map(PathBuf::from)
        .unwrap_or_else(|_| dot().join("cheatsheet.toml"))
}

fn load_sheet() -> Result<Sheet, String> {
    let p = toml_path();
    let raw = std::fs::read_to_string(&p)
        .map_err(|e| format!("reading {}: {e}", p.display()))?;
    toml::from_str(&raw).map_err(|e| format!("parsing {}: {e}", p.display()))
}

fn cmd_gen(out: Option<String>) -> Result<(), String> {
    let sheet = load_sheet()?;
    let tpl_path = dot().join("templates/shell.html");
    let template = std::fs::read_to_string(&tpl_path)
        .map_err(|e| format!("reading template {}: {e}", tpl_path.display()))?;
    let page = html::page(&sheet, &template);
    let out_path = out
        .map(PathBuf::from)
        .unwrap_or_else(|| home().join(".dotfiles/.config/cheatsheet.html"));
    std::fs::write(&out_path, page)
        .map_err(|e| format!("writing {}: {e}", out_path.display()))?;
    eprintln!(
        "cheat: wrote {} ({} cards)",
        out_path.display(),
        sheet.sections.len()
    );
    Ok(())
}

fn cmd_dump(args: &[String]) -> Result<(), String> {
    let sheet = load_sheet()?;
    let width = args
        .iter()
        .find_map(|a| a.parse::<usize>().ok())
        .unwrap_or(80);
    let filter = args
        .iter()
        .find_map(|a| match a.as_str() {
            "nvim" | "lazygit" | "all" => Some(a.as_str()),
            _ => None,
        })
        .unwrap_or("all");
    println!("{}", tui::dump(&sheet, width, filter, ""));
    Ok(())
}

fn cmd_tui() -> Result<(), String> {
    let sheet = load_sheet()?;
    tui::run(&sheet).map_err(|e| format!("tui: {e}"))
}

const HELP: &str = "\
cheat — ejfox's cheatsheet, from one TOML source

  cheat            open the TUI (default)
  cheat gen [out]  regenerate the Hammerspoon HTML panel from the TOML
  cheat help       this help

source of truth: ~/.dotfiles/cheatsheet/cheatsheet.toml

TUI keys:
  j/k ↑/↓   scroll        C-d/C-u   half page
  g / G     top / bottom  space/b   page
  /         search        a/n/l     filter all/nvim/lazygit
  q / esc   quit";

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let result = match args.first().map(String::as_str) {
        None => cmd_tui(),
        Some("gen") => cmd_gen(args.get(1).cloned()),
        Some("dump") => cmd_dump(&args[1..]),
        Some("help" | "-h" | "--help") => {
            println!("{HELP}");
            Ok(())
        }
        Some(other) => Err(format!("unknown command: {other}\n\n{HELP}")),
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("cheat: {e}");
            ExitCode::FAILURE
        }
    }
}
