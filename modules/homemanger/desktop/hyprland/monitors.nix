{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    # See https://wiki.hyprland.org/Configuring/Monitors/
    # List current monitors and resolutions possible: hyprctl monitors
    # Format: monitor = [port], resolution, position, scale
    
    # Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
    settings.monitor = [ 
      ",preferred,auto,1.6"
      "HDMI-A-1,1920x1080@60,auto-left,1.25"
      # "HDMI-A-1,1920x1080@60,auto,1.25,transform,3"
      # "HDMI-A-1,disable"
      "DP-3,2560x1440@143.97Hz,auto,1.6"
    ];

    settings.workspace = [
      "1, monitor:HDMI-A-1, default:true"
    ];

    extraConfig = ''
      # hyprlang noerror true
        source = ~/.config/hypr/monitors.conf
        source = ~/.config/hypr/workspaces.conf
      # hyprlang noerror false
    '';
  };

  home.packages = with pkgs; [ nwg-displays ];
}
