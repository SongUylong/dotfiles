{ ... }:
{
  imports = [
    ./options.nix
    ./hyprland
    ./swaylock.nix
    ./wezterm/wezterm.nix
    ./waypaper.nix
    ./gtk.nix
    # Always import all modules; each module uses mkIf to activate conditionally
    ./caelestia.nix
    ./waybar
    ./rofi/rofi.nix
    ./swaync/swaync.nix
    ./swayosd.nix
  ];
}
