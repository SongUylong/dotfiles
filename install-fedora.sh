#!/usr/bin/env bash
# Link dotfiles into ~/.config and ~/.local/bin for Fedora + Hyprland + editors.
set -euo pipefail

if [[ "${EUID:-0}" -eq 0 ]]; then
  echo "Do not run this script as root; it will use sudo when needed."
  exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$REPO/home/.config"

echo "Repo: $REPO"

dnf_install_from_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  mapfile -t PKGS < <(grep -v '^#' "$f" | grep -v '^[[:space:]]*$' || true)
  ((${#PKGS[@]})) || return 0
  echo "Installing (${f##*/}): ${PKGS[*]}"
  # --skip-unavailable: keep going if a name is wrong or missing on this release
  sudo dnf install -y --skip-unavailable "${PKGS[@]}"
}

echo "Installing base packages (Fedora official repos)..."
dnf_install_from_file "$REPO/packages-fedora-base.txt"

ensure_dnf_copr() {
  sudo dnf install -y dnf-plugins-core >/dev/null 2>&1 || sudo dnf install -y 'dnf-plugins-core'
}

if [[ "${ENABLE_NERD_FONTS:-1}" == "1" ]]; then
  echo ""
  echo "Nerd Fonts (COPR: komapro/nerd-fonts, aquacash5/nerd-fonts)."
  echo "To skip: ENABLE_NERD_FONTS=0 $0"
  echo ""
  ensure_dnf_copr
  sudo dnf copr enable -y komapro/nerd-fonts || echo "[warn] COPR komapro/nerd-fonts failed — install fonts manually."
  sudo dnf copr enable -y aquacash5/nerd-fonts || echo "[warn] COPR aquacash5/nerd-fonts failed — Cascadia Nerd may be missing."
  dnf_install_from_file "$REPO/packages-fedora-fonts-copr.txt"
  fc-cache -f 2>/dev/null || true
fi

if [[ "${ENABLE_COPR:-1}" == "1" ]]; then
  echo ""
  echo "Enabling COPR repositories (Hyprland, WezTerm, swww, Bibata)."
  echo "To skip: ENABLE_COPR=0 $0"
  echo ""
  ensure_dnf_copr
  sudo dnf copr enable -y sdegler/hyprland || echo "[warn] COPR sdegler/hyprland failed — Hyprland/swww/cliphist need this repo."
  sudo dnf copr enable -y wezfurlong/wezterm-nightly || echo "[warn] COPR wezterm-nightly failed — install WezTerm from wezterm.org if needed."
  sudo dnf copr enable -y tx0su/bibata-cursor-theme-noarch || echo "[warn] COPR bibata failed — optional."
  echo "Installing COPR packages..."
  dnf_install_from_file "$REPO/packages-fedora-copr.txt"
else
  echo "Skipping COPR (ENABLE_COPR=0). Hyprland/WezTerm/swww are not from stock Fedora — enable COPR or install manually."
fi

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/wayland-sessions" "$HOME/.ssh"

# Extra Wayland session so GDM can list "Hyprland (direct)" if the system hyprland.desktop is hidden
if [[ -f "$REPO/extras/wayland-sessions/hyprland-direct.desktop" ]]; then
  cp -f "$REPO/extras/wayland-sessions/hyprland-direct.desktop" "$HOME/.local/share/wayland-sessions/"
fi

# Config symlinks (whole trees under ~/.config)
for name in \
  hypr waybar rofi environment.d zsh git tmux tmuxinator yazi \
  nvim wezterm opencode neovide fastfetch zellij \
  sketchybar borders aerospace; do
  [[ -d "$CFG/$name" ]] || { echo "skip missing: $name" >&2; continue; }
  ln -sfn "$CFG/$name" "$HOME/.config/$name"
done

# Aerospace also uses a file in $HOME (macOS-style; harmless on Linux if unused)
if [[ -f "$CFG/aerospace/.aerospace.toml" ]]; then
  ln -sfn "$CFG/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"
fi

# Login shell: use repo zshrc + p10k from dotfiles
ln -sfn "$CFG/zsh/.zshrc" "$HOME/.zshrc"
ln -sfn "$CFG/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# Scripts → ~/.local/bin (must precede Hyprland PATH)
for f in "$REPO/bin"/*; do
  [[ -f "$f" && -x "$f" ]] || continue
  ln -sfn "$f" "$HOME/.local/bin/$(basename "$f")"
done

# Cursor / VS Code / Antigravity — merge editors/* → dist + link into ~/.config/.../User
if [[ -x "$REPO/scripts/sync-editors" ]]; then
  echo "Syncing editor settings (Cursor, VS Code, Antigravity)..."
  SKIP_SYNC_EDITORS="${SKIP_SYNC_EDITORS:-0}"
  if [[ "$SKIP_SYNC_EDITORS" != "1" ]]; then
    "$REPO/scripts/sync-editors"
  else
    echo "Skipping sync-editors (SKIP_SYNC_EDITORS=1)"
  fi
fi

# Global git ignore
git config --global core.excludesfile "$HOME/.config/git/.gitignore" 2>/dev/null || true

if command -v zsh >/dev/null; then
  echo "To use zsh by default: chsh -s $(command -v zsh)"
fi

if [[ ! -e "$HOME/dotfiles" && "$REPO" != "$HOME/dotfiles" ]]; then
  echo "Tip: clone or symlink this repo to ~/dotfiles so hyprlock wallpaper path matches."
fi

echo "Done. Log out and back in (or reboot) so environment.d and Hyprland pick up changes."
echo "GDM: click your user first — then look for a session menu (gear or “Session”) before typing the password."
echo "If only GNOME appears: ~/.local/share/wayland-sessions/hyprland-direct.desktop adds “Hyprland (direct)”; or set Session=hyprland in /var/lib/AccountsService/users/\$USER (see README)."
echo "Zinit will clone plugin repos on first zsh start (needs git + network)."
echo "Neovim: run nvim and let LazyVim sync plugins (:Lazy on first launch)."
