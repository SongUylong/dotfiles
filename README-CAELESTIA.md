# Caelestia Shell Configuration

## Branch: `caelestia-shell`

This branch contains a complete Caelestia shell configuration integrated with your Stylix theming.

## What's Configured

### 1. Flake Input
- Added `caelestia-shell` from `github:caelestia-dots/shell`
- Automatically includes the CLI tools

### 2. Caelestia Configuration (`modules/homemanger/desktop/caelestia.nix`)

**Features:**
- ✅ Full Material Design 3 theming synced with Stylix colors
- ✅ Desktop clock background
- ✅ Custom launcher with system actions (calculator, wallpaper, power management, etc.)
- ✅ Integrated status bar with audio, network, tray
- ✅ Vim keybindings in launcher
- ✅ Fuzzy search for apps, actions, schemes
- ✅ CLI theme management (disabled for Stylix-managed components)

**Stylix Integration:**
- Wallpaper path automatically synced
- Color scheme generated from your Stylix base16 colors
- Fonts inherited from Stylix configuration
- Mode (light/dark) follows Stylix polarity

### 3. Launcher Actions
- Calculator (Qalc)
- Scheme/Wallpaper/Variant switchers
- Random wallpaper
- Light/Dark mode toggle
- System power actions (poweroff, reboot, logout, lock, sleep)
- Settings control center

## How to Use

### Switch to Caelestia Branch
```bash
git checkout caelestia-shell
```

### Build and Apply
```bash
sudo nixos-rebuild switch --flake .#desktop
```

### Return to Your Previous Setup
```bash
git checkout optimization  # or your main branch
sudo nixos-rebuild switch --flake .#desktop
```

## What Gets Replaced

When using Caelestia:
- **Waybar** → Caelestia bar
- **Rofi** → Caelestia launcher
- Other components (Hyprland, Wezterm, etc.) continue working as normal

## Customization

Edit `modules/homemanger/desktop/caelestia.nix` to customize:
- Bar appearance and entries
- Launcher actions
- Background settings
- Border rounding and thickness
- Status icons visibility
- And more...

All Caelestia options are documented in the module configuration.

## Notes

- The configuration uses your existing wallpapers directory (`../../wallpapers`)
- Terminal is set to `wezterm`
- File explorer is `yazi` launched in wezterm
- All theme management via Stylix is preserved
