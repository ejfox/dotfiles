#!/bin/bash
# Sync dotfiles and recreate all symlinks
set -e

cd ~/.dotfiles

# Pull latest changes (stash local changes if needed)
if ! git diff --quiet 2>/dev/null; then
  echo "Stashing local changes..."
  git stash
  git pull origin main
  git stash pop
else
  git pull origin main
fi

# Ensure ~/.config exists
mkdir -p ~/.config

# Core dotfiles
ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.startup.sh ~/.startup.sh
ln -sf ~/.dotfiles/.zen-mode.sh ~/.zen-mode.sh
ln -sf ~/.dotfiles/.p10k.zsh ~/.p10k.zsh
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/.zprofile ~/.zprofile
ln -sf ~/.dotfiles/.bash_profile ~/.bash_profile
ln -sf ~/.dotfiles/.zshenv ~/.zshenv
ln -sf ~/.dotfiles/.llm-persona.txt ~/.llm-persona.txt

# macOS app support symlinks (apps that read from ~/Library instead of ~/.config)
mkdir -p ~/Library/Application\ Support/jesseduffield/lazygit
ln -sf ~/.config/lazygit/config.yml ~/Library/Application\ Support/jesseduffield/lazygit/config.yml

# Config directories
ln -sf ~/.dotfiles/.config/nvim ~/.config/nvim
ln -sf ~/.dotfiles/.config/ghostty ~/.config/ghostty
ln -sf ~/.dotfiles/.config/yazi ~/.config/yazi
ln -sf ~/.dotfiles/.config/btop ~/.config/btop
ln -sf ~/.dotfiles/.config/minimal-prompt.zsh ~/.config/minimal-prompt.zsh
ln -sf ~/.dotfiles/.config/atuin ~/.config/atuin
ln -sf ~/.dotfiles/.config/bat ~/.config/bat
ln -sf ~/.dotfiles/.config/karabiner ~/.config/karabiner
ln -sf ~/.dotfiles/.config/lazygit ~/.config/lazygit
ln -sf ~/.dotfiles/.config/sketchybar ~/.config/sketchybar
ln -sf ~/.dotfiles/.config/zsh ~/.config/zsh
ln -sf ~/.dotfiles/.config/fzf ~/.config/fzf

# Talon voice control overrides (-n: replace the symlink itself, don't descend into it)
ln -sfn ~/.dotfiles/talon-overrides ~/.talon/user/talon-overrides

# OBS: link whole DIRECTORIES — OBS saves via temp-file + rename, which would replace a
# per-file symlink with a plain file. Moves a real dir aside once (never deletes).
link_dir() {
  if [ -e "$2" ] && [ ! -L "$2" ]; then mv "$2" "$2.pre-dotfiles-$(date +%Y%m%d-%H%M%S)"; fi
  mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"
}
OBS_DIR=~/Library/Application\ Support/obs-studio
link_dir ~/.dotfiles/obs/basic "$OBS_DIR/basic"
link_dir ~/.dotfiles/obs/plugin_config/obs-midi-mg "$OBS_DIR/plugin_config/obs-midi-mg"
# UDID-scrubbing git filter for OBS scene collections (config isn't versioned, so set it here)
git config filter.obs-redact.clean "sed -E 's/\"setting_device_uuid\": *\"[^\"]*\"/\"setting_device_uuid\": \"REDACTED-IPHONE-UDID\"/'"
git config filter.obs-redact.smudge cat

# Enable pre-commit security hook
git config core.hooksPath .githooks

echo "Dotfiles synced and symlinked."
echo "Run 'dotfiles-verify' to check everything is working."
