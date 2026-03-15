{
  host,
  config,
  lib,
  ...
}:
lib.mkIf (!config.desktop.useCaelestia) {
  programs.waybar.settings.mainBar = {
    position = "top";
    layer = "top";
    height = 36;
    margin-top = 4;
    margin-bottom = 0;
    margin-left = 6;
    margin-right = 6;
    modules-left = [
      "custom/launcher"
      "hyprland/workspaces"
    ];
    modules-center = [ "custom/clock" ];
    modules-right = [
      "pulseaudio"
      "bluetooth"
      "network"
      "battery"
      "custom/language"
      "custom/notification"
      "custom/power-menu"
    ];
    "custom/clock" = {
      exec = "date +'%H:%M'";
      interval = 10;
      format = " {}";
      tooltip = true;
      tooltip-format = "{}";
      exec-if = "true";
    };
    "hyprland/workspaces" = {
      active-only = false;
      disable-scroll = true;
      format = "{icon}";
      on-click = "activate";
      format-icons = {
        "1" = "I";
        "2" = "II";
        "3" = "III";
        "4" = "IV";
        "5" = "V";
        "6" = "VI";
        "7" = "VII";
        "8" = "VIII";
        "9" = "IX";
        "10" = "X";
        sort-by-number = true;
      };
      persistent-workspaces = {
        "1" = [ ];
        "2" = [ ];
        "3" = [ ];
        "4" = [ ];
        "5" = [ ];
      };
    };
    bluetooth = {
      format = "󰂯 ";
      format-disabled = "󰂲 ";
      format-off = "󰂲 ";
      format-connected = "󰂱 ";
      tooltip-format = "{controller_alias}\t{controller_address}";
      tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
      tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
      on-click = "blueman-manager";
    };
    network = {
      format-wifi = "󰤨 {essid} {signalStrength}%";
      format-ethernet = "󰀂 ";
      tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
      format-linked = "{ifname} (No IP)";
      format-disconnected = "󰤭 ";
      on-click = "wezterm start --always-new-process network";
    };
    pulseaudio = {
      format = "{icon} {volume}%";
      format-muted = "󰝟 {volume}%";
      format-icons = {
        default = [ "󰕾 " ];
      };
      scroll-step = 2;
      on-click = "pamixer -t";
      on-click-right = "pavucontrol";
    };
    battery = {
      format = "{icon} {capacity}%";
      format-icons = [
        "󰁺"
        "󰁼"
        "󰁿"
        "󰂁"
        "󰁹"
      ];
      format-charging = "󰂄 {capacity}%";
      format-full = "󰁹 {capacity}%";
      format-warning = "󰁻 {capacity}%";
      interval = 5;
      states = {
        warning = 20;
      };
      format-time = "{H}h{M}m";
      tooltip = true;
      tooltip-format = "{time}";
    };
    "custom/language" = {
      format = "󰌌 {}";
      exec = "keyboard-layout";
      interval = 1;
      on-click = "hyprctl switchxkblayout at-translated-set-2-keyboard next";
      tooltip = true;
      tooltip-format = "Keyboard layout - Click to switch";
    };
    "custom/launcher" = {
      format = "󱓞";
      on-click = "random-wallpaper";
      on-click-right = "rofi -show drun";
      tooltip = true;
      tooltip-format = "Random Wallpaper / Right-click: App Launcher";
    };
    "custom/notification" = {
      tooltip = true;
      tooltip-format = "Notifications";
      format = "{icon}";
      format-icons = {
        notification = "󰂚";
        none = "󰂜";
        dnd-notification = "󰂛";
        dnd-none = "󰂛";
        inhibited-notification = "󰂚";
        inhibited-none = "󰂜";
        dnd-inhibited-notification = "󰂛";
        dnd-inhibited-none = "󰂛";
      };
      return-type = "json";
      exec-if = "which swaync-client";
      exec = "swaync-client -swb";
      on-click = "swaync-client -t -sw";
      on-click-right = "swaync-client -d -sw";
      escape = true;
    };
    "custom/power-menu" = {
      tooltip = true;
      tooltip-format = "Power menu";
      format = "󰐥";
      on-click = "power-menu";
    };
  };
}
