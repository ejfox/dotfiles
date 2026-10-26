# ejfox's dotfiles

Rules and gotchas only. Feature history, setup logs and per-plugin notes live in
`docs/CLAUDE-NOTES.md`. It doesn't load automatically, so read the section for a feature before changing it.

## Git
- **Don't sign commits.** EJ signs his own with `git cs` (`commit -S`). Unsigned commits mark Claude's work.
- Stage only your own hunks; other sessions often leave uncommitted work here.

## Shell and PATH
- `~/.zshrc` is a symlink to `~/.dotfiles/.zshrc`. Secrets live in `~/.env` (gitignored, sourced). Never commit them.
- `/opt/homebrew/bin` must stay on PATH. Base: `$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin`.
- `c` is a zsh alias, so a shell function named `c()` won't parse.

## Secrets (incident, Nov 2025)
- 9 API keys were committed and had to be scrubbed from git history with a force-push. `.gitignore` now covers `.env`, `.env.*`, `*.key`, `*.pem`, `claude.json`, `Library/`.
- Run the global secret scan before every commit here. The pre-commit hook also scans.

## Neovim binary
- Homebrew has no Intel bottle for nvim 0.12. `~/.local/bin/nvim` points to the official build in `~/.local/opt/nvim-0.12.6/`. 0.12.5 and 0.11.6 are kept as fallbacks.
- Upgrade: get the release tarball, unpack it into `~/.local/opt/`, run `xattr -dr com.apple.quarantine`, then repoint the symlink.
- `tree-sitter-cli` (brew) is required. nvim-treesitter compiles its parsers with it.

## Theme and Ghostty
- A theme that's broken or unreadable in dark or light mode: run `theme`. See `docs/THEME-SYSTEM.md`.
- Ghostty's bloom shader blooms red and pink pixels. For selections and highlights, use a dark background with white text, not bright saturated colors.

## Things 3
- `things-cli` and the things MCP are read-only. Add tasks with `open -g "things:///add?title=…&notes=…&when=today"`, URL-encoded (`-g` keeps focus; the guard hook blocks plain `open`).
- Prefix titles with the action type: `FIX:`, `VERIFY:`, `UPGRADE:`, `INVESTIGATE:`, `CONSIDER:`, `MONITOR:`, `OPTIONAL:`.

## Elsewhere
- Archive wiki (archive.ejfox.com): MediaWiki API. Credentials are in `~/.claude-secrets`; read them inside a script, never echo them. The guard hook blocks sourcing that file and calling curl in the same command.
- Codex: `~/.codex/config.toml` and `~/.codex/rules/default.rules`. Check the rules file itself before claiming what Codex can or can't do.
- Usage logs: `~/.local/share/usage-logs/{shell,nvim,tmux}/YYYY-MM-DD.jsonl`, summarized by `usage-summary` and `usage-analyze`.
