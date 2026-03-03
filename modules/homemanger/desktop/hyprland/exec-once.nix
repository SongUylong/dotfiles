{ config, lib, ... }:
let
  useCaelestia = config.desktop.useCaelestia;
in
{
  wayland.windowManager.hyprland.settings.exec-once = [
    # shared startup
    "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    "hyprlock"

    "nm-applet &"
    "poweralertd &"
    "wl-clip-persist --clipboard both &"
    "wl-paste --watch cliphist store &"
    "udiskie --automount --notify --smart-tray &"
    "hyprctl setcursor Bibata-Modern-Ice 24 &"
    "init-wallpaper &"

    "[workspace 1 silent] firefox"
    "[workspace 2 silent] wezterm"
  ]
  ++ lib.optionals (!useCaelestia) [
    # Classic stack: start bar, notifications, and idle daemon
    "LANG=en_US.UTF-8 waybar &"
    "swaync &"
    "hypridle &"
  ];
  # Caelestia handles its own bar, notifications, and idle via its systemd service
}
