{ ... }:
{
  programs.waybar.style = ''
    * {
      font-family: "Maple Mono", "Font Awesome 6 Free";
      font-size: 13px;
      font-weight: bold;
      min-height: 0;
    }

    window#waybar {
      background: #1e1e2e;
      border-bottom: 2px solid #89b4fa;
    }

    #workspaces {
      background: transparent;
      margin: 2px 4px 2px 4px;
      padding: 0 2px;
    }

    #workspaces button {
      padding: 0 8px;
      margin: 0 2px;
      background: transparent;
      color: @theme_text_color;
      border-radius: 4px;
      min-width: 24px;
    }

    #workspaces button.active {
      background: @theme_selected_bg_color;
      color: @theme_selected_fg_color;
    }

    #workspaces button:hover {
      background: rgba(255, 255, 255, 0.1);
    }

    #custom-launcher,
    #tray,
    #clock,
    #pulseaudio,
    #bluetooth,
    #network,
    #battery,
    #custom-language,
    #custom-notification,
    #custom-power-menu {
      background: transparent;
      padding: 0 8px;
      margin: 0 2px;
    }

    #tray {
      padding-right: 4px;
    }

    #tray > .passive {
      -gtk-icon-effect: dim;
    }

    #tray > .needs-attention {
      -gtk-icon-effect: highlight;
    }

    #clock {
      font-weight: bold;
      padding: 0 12px;
    }

    #pulseaudio {
      min-width: 50px;
    }

    #battery {
      min-width: 50px;
    }

    #battery.warning {
      color: #f9e2af;
    }

    #battery.critical:not(.charging) {
      color: #f38ba8;
      animation: blink 0.5s linear infinite alternate;
    }

    @keyframes blink {
      to {
        color: #181825;
      }
    }

    tooltip {
      background: @theme_bg_color;
      border: 1px solid @theme_selected_bg_color;
      border-radius: 6px;
      padding: 8px;
    }

    tooltip label {
      color: @theme_text_color;
    }
  '';
}
