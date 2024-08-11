#!/bin/bash

# File: ~/sync-dotfiles.sh

# Navigate to dotfiles directory
cd ~/.dotfiles

# Pull latest changes
git pull origin main

# Re-create symlink (in case the file was added recently)
ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf

echo "Dotfiles synced successfully!"