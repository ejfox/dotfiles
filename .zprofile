# Zsh profile - runs once per login session
# Main config lives in .zshrc
# Machine-specific overrides in .zshrc.local (not synced)

# SSH login shells need .zshrc sourced explicitly (skip if interactive — zsh handles it)
[[ ! -o interactive && -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
