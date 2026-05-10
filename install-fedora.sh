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

if [[ "${INSTALL_ANTIGRAVITY:-0}" == "1" ]]; then
  echo ""
  echo "Antigravity editor (RPM repo from Google Artifact Registry; gpgcheck=0 per upstream)."
  echo "To skip: INSTALL_ANTIGRAVITY=0 $0"
  echo ""
  if [[ -f "$REPO/extras/yum.repos.d/antigravity.repo" ]]; then
    sudo install -m 644 "$REPO/extras/yum.repos.d/antigravity.repo" /etc/yum.repos.d/antigravity.repo
    ensure_dnf_copr
    sudo dnf makecache -y
    sudo dnf install -y antigravity
  else
    echo "[warn] Missing $REPO/extras/yum.repos.d/antigravity.repo"
  fi
fi

# ─── NVIDIA proprietary driver ─────────────────────────────────────────────────
# Installs from RPM Fusion nonfree (nvidia-driver repo).
# To skip: INSTALL_NVIDIA=0 ./install-fedora.sh
if [[ "${INSTALL_NVIDIA:-1}" == "1" ]]; then
  echo ""
  echo "NVIDIA proprietary driver (RPM Fusion nonfree)."
  echo "To skip: INSTALL_NVIDIA=0 $0"
  echo ""

  # Detect if an NVIDIA GPU is present
  if lspci | grep -qi 'vga.*nvidia'; then
    # Enable RPM Fusion nonfree if not already
    if ! dnf repolist | grep -q rpmfusion-nonfree; then
      echo "Enabling RPM Fusion nonfree..."
      sudo dnf install -y \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" || true
    fi

    echo "Installing NVIDIA proprietary driver..."
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

    echo "Building NVIDIA kernel module (this may take a few minutes)..."
    sudo akmods --force

    # NVIDIA kernel module options: modeset, framebuffer console, PAT, VRAM preserve
    NVIDIA_MODPROBE="/etc/modprobe.d/nvidia.conf"
    if [[ ! -f "$NVIDIA_MODPROBE" ]]; then
      sudo tee "$NVIDIA_MODPROBE" > /dev/null <<'EOF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_UsePageAttributeTable=1
options nvidia_drm modeset=1 fbdev=1
EOF
      echo "  ✓ Created $NVIDIA_MODPROBE"
    fi

    # Early-load NVIDIA modules in initramfs for faster boot
    DRACUT_NVIDIA="/etc/dracut.conf.d/nvidia.conf"
    if [[ ! -f "$DRACUT_NVIDIA" ]]; then
      echo 'force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "' \
        | sudo tee "$DRACUT_NVIDIA" > /dev/null
      echo "  ✓ Created $DRACUT_NVIDIA (early-load NVIDIA in initramfs)"
    fi

    sudo dracut --force

    # Add NVIDIA DRM modeset + fbdev to GRUB kernel command line
    if ! grep -q 'nvidia-drm.modeset=1' /proc/cmdline 2>/dev/null; then
      sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
      echo "  ✓ Added nvidia-drm.modeset=1 nvidia-drm.fbdev=1 to GRUB"
    fi

    # Enable NVIDIA suspend/resume/hibernate services
    sudo systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate 2>/dev/null || true
    echo "  ✓ Enabled nvidia-suspend/resume/hibernate services"

    echo "NVIDIA driver installed. A reboot is required."
  else
    echo "[skip] No NVIDIA GPU detected — skipping driver install."
  fi
else
  echo "Skipping NVIDIA driver (INSTALL_NVIDIA=0)."
fi

# ─── System performance tuning ─────────────────────────────────────────────────
# To skip: TUNE_PERFORMANCE=0 ./install-fedora.sh
if [[ "${TUNE_PERFORMANCE:-1}" == "1" ]]; then
  echo ""
  echo "Applying system performance tuning..."

  # CPU governor → performance (install cpupower if missing)
  if ! command -v cpupower &>/dev/null; then
    sudo dnf install -y kernel-tools
  fi
  echo 'GOVERNOR="performance"' | sudo tee /etc/sysconfig/cpupower >/dev/null
  sudo systemctl enable cpupower 2>/dev/null || true
  # Apply immediately (harmless if already set)
  sudo cpupower frequency-set -g performance 2>/dev/null || true
  echo "  ✓ CPU governor → performance"

  # Kernel sysctl tuning: swappiness, cache pressure, BBR + CAKE
  sudo tee /etc/sysctl.d/99-performance.conf > /dev/null <<'EOF'
# zram works well with moderate swappiness
vm.swappiness = 30
# Keep filesystem metadata caches longer
vm.vfs_cache_pressure = 50
# BBR congestion control + CAKE qdisc for better network throughput
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
EOF
  sudo sysctl --system > /dev/null 2>&1
  echo "  ✓ sysctl: swappiness=30, vfs_cache_pressure=50, BBR+CAKE"

  # I/O scheduler → mq-deadline for SSDs
  UDEV_IO="/etc/udev/rules.d/60-io-scheduler.conf"
  if [[ ! -f "$UDEV_IO" ]]; then
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"' \
      | sudo tee "$UDEV_IO" >/dev/null
    echo "  ✓ I/O scheduler → mq-deadline (SSD)"
  else
    echo "  · $UDEV_IO already exists — skipping"
  fi

  # TuneD → desktop profile for lower interactive latency
  if command -v tuned-adm &>/dev/null; then
    sudo tuned-adm profile desktop 2>/dev/null || true
    echo "  ✓ TuneD profile → desktop"
  fi
fi

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/wayland-sessions" "$HOME/.ssh"

# Extra Wayland session so GDM can list "Hyprland (direct)" if the system hyprland.desktop is hidden
if [[ -f "$REPO/extras/wayland-sessions/hyprland-direct.desktop" ]]; then
  cp -f "$REPO/extras/wayland-sessions/hyprland-direct.desktop" "$HOME/.local/share/wayland-sessions/"
fi

# Set Hyprland as the default GDM session (AccountsService)
# To skip: SET_DEFAULT_SESSION=0 ./install-fedora.sh
if [[ "${SET_DEFAULT_SESSION:-1}" == "1" ]]; then
  ACCT_FILE="/var/lib/AccountsService/users/$USER"
  echo "Setting Hyprland as default GDM session for $USER..."
  if [[ -f "$ACCT_FILE" ]]; then
    # Update existing file: replace or add Session= line under [User]
    if grep -q '^Session=' "$ACCT_FILE" 2>/dev/null; then
      sudo sed -i 's/^Session=.*/Session=hyprland/' "$ACCT_FILE"
    else
      sudo sed -i '/^\[User\]/a Session=hyprland' "$ACCT_FILE"
    fi
  else
    # Create the file from scratch
    sudo mkdir -p /var/lib/AccountsService/users
    printf '[User]\nSession=hyprland\n' | sudo tee "$ACCT_FILE" >/dev/null
  fi
  echo "Default session → hyprland (in $ACCT_FILE)."
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

# ─── GDM autologin (skip GDM greeter → boot straight into Hyprland + hyprlock) ─
# Enabled by default so the user sees only hyprlock, not GDM then hyprlock.
# To disable: ENABLE_GDM_AUTOLOGIN=0 ./install-fedora.sh
if [[ "${ENABLE_GDM_AUTOLOGIN:-1}" == "1" ]]; then
  echo ""
  echo "Enabling GDM automatic login for $USER (skip GDM greeter → hyprlock only)."
  echo "To disable later: sudo $REPO/scripts/disable-gdm-autologin"
  sudo "$REPO/scripts/enable-gdm-autologin" "$USER" || echo "[warn] GDM autologin step failed."
fi

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  Done! Reboot to apply all changes."
echo ""
echo "  After reboot, verify:"
echo "    lsmod | grep nvidia           # NVIDIA driver loaded"
echo "    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor  # performance"
echo "    cat /proc/sys/vm/swappiness   # 10"
echo "══════════════════════════════════════════════════════════════════════"
echo ""
echo "  Zinit will clone plugin repos on first zsh start (needs git + network)."
echo "  Neovim: run nvim and let LazyVim sync plugins (:Lazy on first launch)."
