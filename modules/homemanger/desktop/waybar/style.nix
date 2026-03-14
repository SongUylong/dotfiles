{ config, lib, ... }:
lib.mkIf (!config.desktop.useCaelestia) {
  programs.waybar.style = ''
    * {
      font-family: "Maple Mono NF", "Font Awesome 6 Free";
      font-size: 13px;
      font-weight: bold;
      min-height: 0;
      border: none;
      border-radius: 0;
      padding: 0;
      margin: 0;
    }

    window#waybar > box {
      min-height: 0;
    }

    .modules-left > widget,
    .modules-center > widget,
    .modules-right > widget {
      min-height: 0;
    }

    /* Catppuccin Mocha palette */
    /* base:    #1e1e2e  mantle: #181825  crust:   #11111b  */
    /* surface0:#313244  surface1:#45475a overlay0:#6c7086  */
    /* text:    #cdd6f4  blue:   #89b4fa  mauve:   #cba6f7  */
    /* green:   #a6e3a1  red:    #f38ba8  peach:   #fab387  */
    /* yellow:  #f9e2af  teal:   #94e2d5  sapphire:#74c7ec  */

    window#waybar {
      background: transparent;
    }

    .modules-left,
    .modules-center,
    .modules-right {
      background: #1e1e2e;
      border-radius: 10px;
      margin: 4px 3px;
      padding: 0 4px;
    }

    .modules-left {
      margin-right: 0;
    }

    .modules-right {
      margin-left: 0;
    }

    /* --- Workspaces --- */
    #workspaces {
      padding: 0 2px;
    }

    #workspaces button {
      padding: 0 8px;
      margin: 3px 2px;
      background: transparent;
      color: #6c7086;
      border-radius: 7px;
      font-weight: bold;
      min-height: 22px;
    }

    #workspaces button:hover {
      background: #313244;
      color: #cdd6f4;
    }

    #workspaces button.active {
      background: #89b4fa;
      color: #1e1e2e;
    }

    #workspaces button.urgent {
      background: #f38ba8;
      color: #1e1e2e;
    }

    /* --- Shared module pill style --- */
    #pulseaudio,
    #bluetooth,
    #network,
    #battery,
    #custom-language,
    #custom-notification,
    #custom-power-menu,
    #custom-launcher {
      padding: 0 8px;
      margin: 3px 2px;
      border-radius: 7px;
      font-weight: bold;
      min-height: 22px;
      color: #1e1e2e;
    }

    /* --- Clock (no colored background, uses section bg) --- */
    #custom-clock {
      padding: 0 8px;
      margin: 3px 2px;
      min-height: 22px;
      color: #cdd6f4;
      font-weight: bold;
    }

    /* --- Tray --- */
    #tray {
      padding: 0 6px;
      margin: 3px 2px;
      min-height: 22px;
      color: #cdd6f4;
    }

    #tray > .passive {
      -gtk-icon-effect: dim;
    }

    #tray > .needs-attention {
      -gtk-icon-effect: highlight;
      background: #f38ba8;
      border-radius: 7px;
    }

    /* --- Individual module colors --- */
    #custom-launcher {
      background: #cba6f7;
      font-size: 15px;
      padding: 0 10px;
    }

    #pulseaudio {
      background: #89b4fa;
    }

    #pulseaudio.muted {
      background: #45475a;
      color: #6c7086;
    }

    #bluetooth {
      background: #74c7ec;
    }

    #bluetooth.disabled,
    #bluetooth.off {
      background: #45475a;
      color: #6c7086;
    }

    #network {
      background: #a6e3a1;
    }

    #network.disconnected {
      background: #f38ba8;
    }

    #battery {
      background: #a6e3a1;
    }

    #battery.warning {
      background: #f9e2af;
    }

    #battery.critical:not(.charging) {
      background: #f38ba8;
      animation: blink 0.5s linear infinite alternate;
    }

    #battery.charging {
      background: #a6e3a1;
    }

    @keyframes blink {
      to { color: #1e1e2e; }
    }

    #custom-language {
      background: #f9e2af;
    }

    #custom-notification {
      background: #fab387;
    }

    #custom-power-menu {
      background: #f38ba8;
      font-size: 15px;
    }

    /* --- Tooltip --- */
    tooltip {
      background: #181825;
      border: 1px solid #313244;
      border-radius: 10px;
      padding: 6px;
    }

    tooltip label {
      color: #cdd6f4;
    }
  '';
}
