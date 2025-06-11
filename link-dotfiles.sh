#!/bin/bash

set -e

BACKUP_DIR="$HOME/.config-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "🔗 Creating symlinks for dotfiles (with backups)..."

# Symlink for Neovim
if [ -e "$HOME/.config/nvim" ]; then
  echo "📦 Backing up ~/.config/nvim to $BACKUP_DIR"
  mv "$HOME/.config/nvim" "$BACKUP_DIR/"
fi
ln -s "$HOME/dotfiles/config/nvim" "$HOME/.config/nvim"
echo "✅ Linked nvim config"

# Symlink for WezTerm
if [ -e "$HOME/.config/wezterm" ]; then
  echo "📦 Backing up ~/.config/wezterm to $BACKUP_DIR"
  mv "$HOME/.config/wezterm" "$BACKUP_DIR/"
fi
ln -s "$HOME/dotfiles/config/wezterm" "$HOME/.config/wezterm"
echo "✅ Linked wezterm config"

# Symlink for .zshrc
if [ -e "$HOME/.zshrc" ]; then
  echo "📦 Backing up ~/.zshrc to $BACKUP_DIR"
  mv "$HOME/.zshrc" "$BACKUP_DIR/"
fi
ln -s "$HOME/dotfiles/home/.zshrc" "$HOME/.zshrc"
echo "✅ Linked .zshrc"

echo "🎉 All done! Backups saved in $BACKUP_DIR"
