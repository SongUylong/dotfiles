#!/usr/bin/env bash
# ==============================================================================
#  install.sh — symlink dotfiles to ~/.config + editor apps (Cursor, VS Code, Antigravity)
# ==============================================================================
# Editor config: all sources under ~/dotfiles/editors/
#   settings.shared.json, keybindings.json, extensions.txt, overrides/*.json
# Optional: INSTALL_EDITOR_EXTENSIONS=1  — also install extensions from extensions.txt
# Optional: SKIP_SYNC_EDITORS=1          — skip Cursor/VS Code/Antigravity linking
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

# ── Cursor / VS Code / Antigravity (sources: ~/dotfiles/editors/) ─────────────
if [[ -x "$DOTFILES/scripts/sync-editors" && "${SKIP_SYNC_EDITORS:-0}" != "1" ]]; then
  echo -e "\n${BOLD} Editor apps (Cursor, VS Code, Antigravity) ${RESET}\n"
  SYNC_ARGS=()
  if [[ "${INSTALL_EDITOR_EXTENSIONS:-0}" == "1" ]]; then
    SYNC_ARGS+=(--install-extensions)
  fi
  if ((${#SYNC_ARGS[@]} > 0)); then
    "$DOTFILES/scripts/sync-editors" "${SYNC_ARGS[@]}"
  else
    "$DOTFILES/scripts/sync-editors"
  fi
fi

echo -e "\n${BOLD}${GREEN} Done!${RESET} Run ${BOLD}exec zsh${RESET} to reload your shell.\n"
