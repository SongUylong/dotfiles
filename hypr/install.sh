#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
FONTS_DIR="$HOME/.local/share/fonts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to check if package is installed
is_installed() {
    pacman -Qi "$1" &> /dev/null
}

# Helper function to install package if not already installed
install_if_needed() {
    local package=$1
    if is_installed "$package"; then
        echo -e "${YELLOW}  ⏭  $package already installed, skipping${NC}"
    else
        echo -e "${GREEN}  ⬇  Installing $package${NC}"
        sudo pacman -S --noconfirm --needed "$package"
    fi
}

# Helper function to install AUR package with yay if not already installed
install_aur_if_needed() {
    local package=$1
    if is_installed "$package"; then
        echo -e "${YELLOW}  ⏭  $package already installed, skipping${NC}"
    else
        echo -e "${GREEN}  ⬇  Installing $package from AUR${NC}"
        yay -S --noconfirm --needed "$package"
    fi
}

echo "==> Updating system..."
sudo pacman -Syu --noconfirm

# ---------------------------------------------------
# Install yay if not installed (AUR helper)
# ---------------------------------------------------
if ! command -v yay &> /dev/null; then
    echo "==> Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    echo -e "${GREEN} -> yay installed${NC}"
else
    echo -e "${GREEN}==> yay already installed${NC}"
fi

# ---------------------------------------------------
# Core System & Hardware
# ---------------------------------------------------
echo ""
echo "==> Installing Core System & Hardware packages..."
install_if_needed "base"
install_if_needed "base-devel"
install_if_needed "linux"
install_if_needed "linux-headers"
install_if_needed "linux-firmware"
install_if_needed "intel-ucode"
install_if_needed "lm_sensors"

# ---------------------------------------------------
# Shell & Terminal
# ---------------------------------------------------
echo ""
echo "==> Installing Shell & Terminal packages..."
install_if_needed "zsh"
install_if_needed "bash-completion"
install_if_needed "wezterm"
install_if_needed "alacritty"
install_if_needed "starship"

# ---------------------------------------------------
# File Management & CLI Tools
# ---------------------------------------------------
echo ""
echo "==> Installing File Management & CLI Tools..."
install_if_needed "stow"
install_if_needed "yazi"
install_if_needed "lsd"
install_if_needed "eza"
install_if_needed "tree"
install_if_needed "bat"
install_if_needed "dust"
install_if_needed "usage"
install_if_needed "fd"
install_if_needed "ripgrep"
install_if_needed "fzf"
install_if_needed "thefuck"
install_if_needed "zoxide"
install_if_needed "plocate"

# ---------------------------------------------------
# Clipboard & Display
# ---------------------------------------------------
echo ""
echo "==> Installing Clipboard & Display tools..."
install_if_needed "xclip"
install_if_needed "xsel"
install_if_needed "wl-clipboard"
install_if_needed "chafa"
install_if_needed "imagemagick"

# ---------------------------------------------------
# Audio & Bluetooth
# ---------------------------------------------------
echo ""
echo "==> Installing Audio & Bluetooth packages..."
install_if_needed "pipewire"
install_if_needed "pipewire-alsa"
install_if_needed "pipewire-pulse"
install_if_needed "pipewire-jack"
install_if_needed "wireplumber"
install_if_needed "pavucontrol"
install_if_needed "pamixer"
install_if_needed "playerctl"
install_if_needed "bluez"
install_if_needed "bluez-utils"
install_if_needed "bluetui"
install_if_needed "wiremix"

# ---------------------------------------------------
# Hyprland & Wayland Ecosystem
# ---------------------------------------------------
echo ""
echo "==> Installing Hyprland & Wayland packages..."
install_if_needed "hyprland"
install_if_needed "hypridle"
install_if_needed "hyprlock"
install_if_needed "hyprpicker"
install_if_needed "hyprsunset"
install_if_needed "hyprland-guiutils"
install_if_needed "hyprland-preview-share-picker"
install_if_needed "waybar"
install_if_needed "mako"
install_if_needed "swaybg"
install_if_needed "swayosd"
install_if_needed "xdg-desktop-portal-hyprland"
install_if_needed "xdg-desktop-portal-gtk"
install_if_needed "xdg-terminal-exec"
install_if_needed "grim"
install_if_needed "slurp"
install_if_needed "satty"
install_if_needed "wayfreeze"
install_if_needed "brightnessctl"

# ---------------------------------------------------
# Networking
# ---------------------------------------------------
echo ""
echo "==> Installing Networking packages..."
install_if_needed "networkmanager"
install_if_needed "network-manager-applet"
install_if_needed "iwd"
install_if_needed "openvpn"
install_if_needed "wireguard-tools"
install_if_needed "dnsmasq"
install_if_needed "nss-mdns"

# ---------------------------------------------------
# Development Tools
# ---------------------------------------------------
echo ""
echo "==> Installing Development Tools..."
install_if_needed "git"
install_if_needed "github-cli"
install_if_needed "neovim"
install_if_needed "mise"
install_if_needed "docker"
install_if_needed "npm"
install_if_needed "nvm"
install_if_needed "nodejs-lts-iron"
install_if_needed "python"
install_if_needed "python-gobject"
install_if_needed "python-poetry-core"
install_if_needed "ruby"
install_if_needed "rust"
install_if_needed "clang"
install_if_needed "llvm"
install_if_needed "kubectl"
install_if_needed "lazydocker"
install_if_needed "lazygit"
install_if_needed "tree-sitter-cli"

# ---------------------------------------------------
# Browsers & Communication
# ---------------------------------------------------
echo ""
echo "==> Installing Browsers & Communication..."
install_if_needed "signal-desktop"

# ---------------------------------------------------
# Productivity & Office
# ---------------------------------------------------
echo ""
echo "==> Installing Productivity & Office apps..."
install_if_needed "libreoffice-fresh"
install_if_needed "obsidian"
install_if_needed "typora"
install_if_needed "xournalpp"
install_if_needed "tldr"
install_if_needed "man-db"
install_if_needed "gnome-calculator"

# ---------------------------------------------------
# Media & Graphics
# ---------------------------------------------------
echo ""
echo "==> Installing Media & Graphics packages..."
install_if_needed "ffmpeg"
install_if_needed "ffmpegthumbnailer"
install_if_needed "imv"
install_if_needed "evince"
install_if_needed "sushi"
install_if_needed "mpv"
install_if_needed "obs-studio"
install_if_needed "kdenlive"
install_if_needed "pinta"
install_if_needed "gpu-screen-recorder"

# ---------------------------------------------------
# System Utilities
# ---------------------------------------------------
echo ""
echo "==> Installing System Utilities..."
install_if_needed "htop"
install_if_needed "btop"
install_if_needed "fastfetch"
install_if_needed "inxi"
install_if_needed "gnome-disk-utility"
install_if_needed "gnome-keyring"
install_if_needed "polkit-gnome"
install_if_needed "power-profiles-daemon"
install_if_needed "powertop"
install_if_needed "tuned"
install_if_needed "ufw"
install_if_needed "ufw-docker"
install_if_needed "snapper"
install_if_needed "zram-generator"
install_if_needed "reflector"

# ---------------------------------------------------
# Fonts
# ---------------------------------------------------
echo ""
echo "==> Installing Fonts..."
install_if_needed "noto-fonts"
install_if_needed "noto-fonts-cjk"
install_if_needed "noto-fonts-emoji"
install_if_needed "noto-fonts-extra"
install_if_needed "ttf-cascadia-mono-nerd"
install_if_needed "ttf-jetbrains-mono-nerd"
install_if_needed "ttf-ia-writer"
install_if_needed "woff2-font-awesome"
install_if_needed "fontconfig"

# ---------------------------------------------------
# File Systems & Storage
# ---------------------------------------------------
echo ""
echo "==> Installing File Systems & Storage packages..."
install_if_needed "btrfs-progs"
install_if_needed "gvfs-mtp"
install_if_needed "gvfs-nfs"
install_if_needed "gvfs-smb"
install_if_needed "nautilus"

# ---------------------------------------------------
# Printing & Scanning
# ---------------------------------------------------
echo ""
echo "==> Installing Printing & Scanning packages..."
install_if_needed "cups"
install_if_needed "cups-pdf"
install_if_needed "cups-filters"
install_if_needed "cups-browsed"
install_if_needed "system-config-printer"
install_if_needed "hplip"
install_if_needed "sane"
install_if_needed "ipp-usb"

# ---------------------------------------------------
# Compression & Archives
# ---------------------------------------------------
echo ""
echo "==> Installing Compression & Archives..."
install_if_needed "7zip"
install_if_needed "unzip"

# ---------------------------------------------------
# Miscellaneous
# ---------------------------------------------------
echo ""
echo "==> Installing Miscellaneous packages..."
install_if_needed "jq"
install_if_needed "wget"
install_if_needed "curl"
install_if_needed "whois"
install_if_needed "ldns"
install_if_needed "gum"
install_if_needed "less"
install_if_needed "tzupdate"
install_if_needed "wireless-regdb"
install_if_needed "xorg-xhost"
install_if_needed "xmlstarlet"
install_if_needed "expac"
install_if_needed "poppler"

# ---------------------------------------------------
# Virtualization & QEMU
# ---------------------------------------------------
echo ""
echo "==> Installing Virtualization packages..."
install_if_needed "qemu-full"
install_if_needed "virt-manager"
install_if_needed "virt-viewer"
install_if_needed "virt-install"
install_if_needed "libvirt"
install_if_needed "swtpm"
install_if_needed "guestfs-tools"
install_if_needed "bridge-utils"

# ---------------------------------------------------
# Display Server Compatibility
# ---------------------------------------------------
echo ""
echo "==> Installing Display Server packages..."
install_if_needed "qt5-wayland"
install_if_needed "qt6-wayland"
install_if_needed "egl-wayland"

# ---------------------------------------------------
# Boot & Init
# ---------------------------------------------------
echo ""
echo "==> Installing Boot & Init packages..."
install_if_needed "limine"
install_if_needed "limine-mkinitcpio-hook"
install_if_needed "limine-snapper-sync"
install_if_needed "plymouth"
install_if_needed "sddm"
install_if_needed "uwsm"

# ---------------------------------------------------
# NVIDIA (if using NVIDIA GPU)
# ---------------------------------------------------
echo ""
echo "==> Installing NVIDIA packages..."
install_if_needed "nvidia-open-dkms"
install_if_needed "nvidia-utils"
install_if_needed "lib32-nvidia-utils"
install_if_needed "libva-nvidia-driver"

# ---------------------------------------------------
# Database & Web Dev
# ---------------------------------------------------
echo ""
echo "==> Installing Database & Web Dev packages..."
install_if_needed "postgresql-libs"
install_if_needed "mariadb-libs"
install_if_needed "php-legacy"
install_if_needed "php-legacy-sodium"

# ---------------------------------------------------
# Input Methods
# ---------------------------------------------------
echo ""
echo "==> Installing Input Methods..."
install_if_needed "fcitx5"
install_if_needed "fcitx5-gtk"
install_if_needed "fcitx5-qt"

# ---------------------------------------------------
# Theming
# ---------------------------------------------------
echo ""
echo "==> Installing Theming packages..."
install_if_needed "kvantum-qt5"
install_if_needed "gnome-themes-extra"
install_if_needed "yaru-icon-theme"

# ---------------------------------------------------
# AUR Packages
# ---------------------------------------------------
echo ""
echo "==> Installing AUR packages..."

# Apps & Tools (AUR only)
install_aur_if_needed "1password"
install_aur_if_needed "1password-cli"
install_aur_if_needed "aether"
install_aur_if_needed "asdcontrol"
install_aur_if_needed "composer"
install_aur_if_needed "cursor-appimage"
install_aur_if_needed "docker-desktop"
install_aur_if_needed "localsend-bin"
install_aur_if_needed "luarocks"
install_aur_if_needed "lynx"
install_aur_if_needed "notion-app-electron"
install_aur_if_needed "omarchy-chromium"
install_aur_if_needed "omarchy-keyring"
install_aur_if_needed "omarchy-nvim"
install_aur_if_needed "omarchy-walker"
install_aur_if_needed "postman-bin"
install_aur_if_needed "proton-vpn-gtk-app"
install_aur_if_needed "spotify"
install_aur_if_needed "tobi-try"

# .NET packages (AUR)
install_aur_if_needed "aspnet-runtime-8.0"
install_aur_if_needed "dotnet-runtime-8.0"
install_aur_if_needed "dotnet-sdk-8.0"

echo ""
echo -e "${GREEN}==> All packages installed!${NC}"

# ---------------------------------------------------
# Bluetooth Setup
# ---------------------------------------------------
echo ""
echo "==> Setting up Bluetooth..."
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
echo -e "${GREEN} -> Bluetooth enabled and started${NC}"

# ---------------------------------------------------
# HP Printer Support
# ---------------------------------------------------
echo ""
echo "==> Setting up HP Printer support..."
sudo systemctl enable cups.service
sudo systemctl start cups.service
echo -e "${GREEN} -> CUPS enabled and started${NC}"
echo -e "${YELLOW} -> Run 'hp-setup' to configure your HP printer${NC}"

# ---------------------------------------------------
# Install Nerd Font: CascadiaCode
# ---------------------------------------------------
echo ""
echo "==> Installing Nerd Font: CascadiaCode"
mkdir -p "$FONTS_DIR"

# Get latest Nerd Fonts release tag
LATEST_NF_TAG=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r '.tag_name')

FONT_ARCHIVE="CascadiaCode.tar.xz"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_NF_TAG}/${FONT_ARCHIVE}"

echo " -> Downloading $FONT_ARCHIVE from $DOWNLOAD_URL"
TEMP_DIR=$(mktemp -d)
curl -L -o "$TEMP_DIR/$FONT_ARCHIVE" "$DOWNLOAD_URL"

echo " -> Extracting fonts..."
tar -xJf "$TEMP_DIR/$FONT_ARCHIVE" -C "$TEMP_DIR"

echo " -> Moving fonts to $FONTS_DIR"
find "$TEMP_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec mv {} "$FONTS_DIR" \;

rm -rf "$TEMP_DIR"

echo " -> Refreshing font cache..."
fc-cache -fv
echo -e "${GREEN} -> Installed CascadiaCode Nerd Font${NC}"

# ---------------------------------------------------
# Stow your dotfiles (overwrite existing configs)
# ---------------------------------------------------
echo ""
echo "==> Stowing dotfiles from $DOTFILES_DIR"
cd "$DOTFILES_DIR"

STOW_MODULES=(
    zsh
    wezterm
    yazi
    nvim
)

for module in "${STOW_MODULES[@]}"; do
    if [[ -d "$module" ]]; then
        echo " -> Stowing $module (overwriting existing files if any)"
        stow -R --override=delete "$module"
    else
        echo -e "${YELLOW} -> Skipping $module (not found)${NC}"
    fi
done

# ---------------------------------------------------
# Stow Hyprland config separately with existing files removed
# ---------------------------------------------------
HYPR_MODULE="hypr"
HYPR_CONFIG_DIR="$HOME/.config/hypr"

if [[ -d "$DOTFILES_DIR/$HYPR_MODULE" ]]; then
    if [[ -d "$HYPR_CONFIG_DIR" ]]; then
        echo " -> Removing existing Hyprland configs to allow stow to overwrite"
        rm -f "$HYPR_CONFIG_DIR"/*
    fi
    echo " -> Stowing Hyprland config"
    stow -R "$HYPR_MODULE"
else
    echo -e "${YELLOW} -> Skipping Hyprland config (not found in dotfiles)${NC}"
fi

# ---------------------------------------------------
# Setup Fan Control (Only if Nuvoton chip is found)
# ---------------------------------------------------
echo ""
echo "==> Configuring Fan Control..."

# Check if the Nuvoton nct67* chip exists on this system
# This prevents errors if you run this script on a laptop or different PC
if grep -r "nct67" /sys/class/hwmon/hwmon*/name 2>/dev/null; then
    echo " -> Nuvoton chip detected. Installing fan control service..."
    
    SERVICE_FILE="/etc/systemd/system/set-fan-speed.service"

    # Write the service file securely
    sudo tee "$SERVICE_FILE" > /dev/null <<'EOF'
[Unit]
Description=Set Fan PWM6 to Constant 120
After=lm_sensors.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for path in /sys/class/hwmon/hwmon*/name; do if grep -q "nct67" "$path"; then dir=$(dirname "$path"); echo 1 > "$dir/pwm6_enable"; echo 120 > "$dir/pwm6"; exit 0; fi; done'

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable the service
    echo " -> Enabling set-fan-speed.service..."
    sudo systemctl daemon-reload
    sudo systemctl enable --now set-fan-speed
    echo -e "${GREEN} -> Fan locked to 120 PWM${NC}"

else
    echo -e "${YELLOW} -> Nuvoton (nct67*) chip NOT found. Skipping fan control setup.${NC}"
fi

# ---------------------------------------------------
# Change default shell to zsh if not already
# ---------------------------------------------------
echo ""
CURRENT_SHELL=$(basename "$SHELL" || echo "")
if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    echo "==> Changing default shell to Zsh..."
    chsh -s "$(which zsh)" && echo -e "${GREEN} -> Default shell changed to zsh. Log out and log in again.${NC}"
else
    echo -e "${GREEN}==> Default shell is already Zsh.${NC}"
fi

echo ""
echo "=============================="
echo -e "${GREEN}Setup complete! 🎉${NC}"
echo " • All packages installed (skipped already installed ones)"
echo " • Dotfiles stowed: ${STOW_MODULES[*]} + hypr"
echo " • Bluetooth & Printing: Configured"
echo " • Fan Control: Configured (if hardware found)"
echo " • Default shell: $(basename "$SHELL")"
echo "=============================="

echo -e "${GREEN}Setup complete! 🎉${NC}"
echo " • All packages installed (skipped already installed ones)"
echo " • Dotfiles stowed: ${STOW_MODULES[*]} + hypr"
echo " • Bluetooth & Printing: Configured"
echo " • Fan Control: Configured (if hardware found)"
echo " • Default shell: $(basename "$SHELL")"
echo "=============================="


