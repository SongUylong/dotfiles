{ lib, ... }:
{
  imports = [ ./default.desktop.nix ];

  desktop.useCaelestia = false;

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,preferred,auto,1.2"
      "HDMI-A-1,1920x1080@143.88,auto-right,1.25"
    ];

    workspace = [
      "1, monitor:eDP-1, default:true"
      "2, monitor:HDMI-A-1, default:true"
    ];

    input = {
      sensitivity = lib.mkForce 0.2;
    };
  };
}
