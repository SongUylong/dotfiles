#!/usr/bin/env bash
# ==============================================================================
#  install.sh — symlink dotfiles to ~/.config
# ==============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.config"

RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"

ok()   { echo -e "${BOLD}${GREEN} ✔ ${RESET} $*"; }
info() { echo -e "${BOLD}${BLUE} ➜ ${RESET} $*"; }
warn() { echo -e "${BOLD}${YELLOW} ⚠ ${RESET} $*"; }

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    warn "$dst exists and is not a symlink — backing up to ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sfn "$src" "$dst"
  ok "$(basename "$dst")"
}

echo -e "\n${BOLD} Linking dotfiles → ~/.config${RESET}\n"

mkdir -p "$CONFIG"

# ── ~/.config/* ───────────────────────────────────────────────────────────────
for dir in \
  nvim opencode tmux tmuxinator \
  wezterm yazi zellij \
  aerospace borders fastfetch neovide sketchybar; do
  link "$DOTFILES/config/$dir" "$CONFIG/$dir"
done

# ── zsh ───────────────────────────────────────────────────────────────────────
mkdir -p "$CONFIG/zsh"
link "$DOTFILES/config/zsh/config.zsh" "$CONFIG/zsh/config.zsh"
link "$DOTFILES/config/zsh/.zshrc"     "$HOME/.zshrc"

# ── aerospace (also reads from HOME) ─────────────────────────────────────────
link "$DOTFILES/config/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"

# ── Cursor / VS Code / Antigravity (shared keybindings, settings, extensions list) ──
if [[ -x "$DOTFILES/bin/sync-editors" && "${SKIP_SYNC_EDITORS:-0}" != "1" ]]; then
  echo -e "\n${BOLD} Editor configs ${RESET}\n"
  "$DOTFILES/bin/sync-editors"
fi

echo -e "\n${BOLD}${GREEN} Done!${RESET} Run ${BOLD}exec zsh${RESET} to reload your shell.\n"
