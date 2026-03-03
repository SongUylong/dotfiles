{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "float 1, match:class ^(Viewnior)$"
      "float 1, match:class ^(imv)$"
      "float 1, match:class ^(mpv)$"
      "pin 1, match:class ^(rofi)$"
      "pin 1, match:class ^(waypaper)$"
      # "hypridle focus, match:class mpv"
      # "float 1, match:class udiskie"
      "float 1, match:title ^(Transmission)$"
      "float 1, match:title ^(Volume Control)$"
      "float 1, match:title ^(Firefox — Sharing Indicator)$"
      "move 0 0, match:title ^(Firefox — Sharing Indicator)$"
      "size 700 450, match:title ^(Volume Control)$"
      "move 40 55%, match:title ^(Volume Control)$"

      "float 1, match:title ^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, match:title ^(Picture-in-Picture)$"
      "pin 1, match:title ^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, match:title ^(.*imv.*)$"
      "opacity 1.0 override 1.0 override, match:title ^(.*mpv.*)$"
      "opacity 1.0 override 1.0 override, match:class (Unity)"
      "opacity 1.0 override 1.0 override, match:class (firefox)"
      "opacity 1.0 override 1.0 override, match:class (evince)"
      "workspace 3, match:class ^(evince)$"
      "workspace 4, match:class ^(Gimp-2.10)$"
      "workspace 5, match:class ^(Spotify)$"
      "workspace 8, match:class ^(com.obsproject.Studio)$"
      "workspace 10, match:class ^(discord)$"
      "workspace 10, match:class ^(WebCord)$"
      # "idle_inhibitor focus, match:class ^(mpv)$"
      # "idle_inhibitor fullscreen, match:class ^(firefox)$"
      "float 1, match:class ^(org.gnome.Calculator)$"
      "float 1, match:class ^(waypaper)$"
      "float 1, match:class ^(zenity)$"
      "size 850 500, match:class ^(zenity)$"
      "float 1, match:class ^(org.gnome.FileRoller)$"
      "float 1, match:class ^(org.pulseaudio.pavucontrol)$"
      "float 1, match:class ^(.sameboy-wrapped)$"
      "float 1, match:class ^(file_progress)$"
      "float 1, match:class ^(confirm)$"
      "float 1, match:class ^(dialog)$"
      "float 1, match:class ^(download)$"
      "float 1, match:class ^(notification)$"
      "float 1, match:class ^(error)$"
      "float 1, match:class ^(confirmreset)$"
      "float 1, match:title ^(Open File)$"
      "float 1, match:title ^(File Upload)$"
      "float 1, match:title ^(branchdialog)$"
      "float 1, match:title ^(Confirm to replace files)$"
      "float 1, match:title ^(File Operation Progress)$"

      "opacity 0.0 override, match:class ^(xwaylandvideobridge)$"
      "no_anim on, match:class ^(xwaylandvideobridge)$"
      "no_initial_focus on, match:class ^(xwaylandvideobridge)$"
      "max_size 1 1, match:class ^(xwaylandvideobridge)$"
      "no_blur on, match:class ^(xwaylandvideobridge)$"

      # No gaps when only
      "border_size 0, match:float 0, match:workspace w[t1]"
      "rounding 0, match:float 0, match:workspace w[t1]"
      "border_size 0, match:float 0, match:workspace w[tg1]"
      "rounding 0, match:float 0, match:workspace w[tg1]"

      # Remove context menu transparency in chromium based apps
      "opaque on, match:class ^()$, match:title ^()$"
      "no_shadow on, match:class ^()$, match:title ^()$"
      "no_blur on, match:class ^()$, match:title ^()$"

      # Prevent Telegram from stealing focus
      "suppress_event activate, match:class ^(telegram-desktop)$"
      "no_focus on, match:class ^(telegram-desktop)$"
    ];

    layerrule = [
      # "dimaround, rofi"
      # "dimaround, swaync-control-center"
    ];

    # No gaps when only
    workspace = [
      "w[t1], gapsout:4 8 8 8, gapsin:4"
      "w[tg1], gapsout:4 8 8 8, gapsin:4"
      "f[1], gapsout:4 8 8 8, gapsin:4"
    ];
  };
}
