{ lib, ... }:
{
  imports = [ ./default.desktop.nix ];

  desktop.useCaelestia = false;

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,1920x1080@144,auto,1.2"
    ];

    input = {
      sensitivity = lib.mkForce 0.2;
    };
  };
}
