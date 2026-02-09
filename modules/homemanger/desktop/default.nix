{ ... }:
{
  imports = [
    ./hyprland
    # ./waybar         # Disabled - Caelestia provides its own bar
    # ./rofi/rofi.nix  # Disabled - Caelestia provides its own launcher
    ./swaylock.nix
    # ./swaync/swaync.nix  # Disabled - Caelestia provides its own notifications
    ./swayosd.nix
    ./wezterm/wezterm.nix
    ./waypaper.nix
    ./gtk.nix
    ./caelestia.nix
  ];
}
