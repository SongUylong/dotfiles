#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
FONTS_DIR="$HOME/.local/share/fonts"

echo "==> Updating system..."
sudo pacman -Syu --noconfirm

echo "==> Installing base packages..."
# Added 'lm_sensors' to this list for fan control support
sudo pacman -S --noconfirm --needed \
    lm_sensors \
    zsh stow wezterm curl unzip xorg-xhost cursor-bin pipewire-pulse bluez bluez-utils pipewire-alsa pavucontrol wireplumber neovim lsd tree fzf thefuck xclip \
    ffmpeg 7zip jq poppler fd ripgrep zoxide imagemagick xsel wl-clipboard chafa

# ---------------------------------------------------
# Install Yazi
# ---------------------------------------------------
echo "==> Installing Yazi..."
sudo pacman -S --noconfirm yazi
echo " -> Yazi installed."

# ---------------------------------------------------
# Install Nerd Font: CascadiaCode
# ---------------------------------------------------
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
echo " -> Installed CascadiaCode Nerd Font"

# ---------------------------------------------------
# Stow your dotfiles (overwrite existing configs)
# ---------------------------------------------------
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
        echo " -> Skipping $module (not found)"
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
    echo " -> Skipping Hyprland config (not found in dotfiles)"
fi

# ---------------------------------------------------
# Setup Fan Control (Only if Nuvoton chip is found)
# ---------------------------------------------------
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
    echo " -> Fan locked to 120 PWM."

else
    echo " -> Nuvoton (nct67*) chip NOT found. Skipping fan control setup."
fi

# ---------------------------------------------------
# Change default shell to zsh if not already
# ---------------------------------------------------
CURRENT_SHELL=$(basename "$SHELL" || echo "")
if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    echo "==> Changing default shell to Zsh..."
    chsh -s "$(which zsh)" && echo " -> Default shell changed to zsh. Log out and log in again."
else
    echo "==> Default shell is already Zsh."
fi

echo ""
echo "=============================="
echo "Setup complete! 🎉"
echo " • Installed packages: zsh, wezterm, yazi, neovim, lm_sensors, etc."
echo " • Dotfiles stowed: ${STOW_MODULES[*]} + hypr"
echo " • Fan Control: Configured (if hardware found)"
echo " • Default shell: $(basename "$SHELL")"
echo "=============================="
