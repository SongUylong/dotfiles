{
  pkgs,
  inputs,
  system,
  ...
}:
let
  customPkgs = import ../../../../pkgs { inherit inputs pkgs system; };
in
{
  home.packages = with pkgs; [
    ## Browsers
    brave

    ## Multimedia
    ffmpeg # For GIF conversion
    media-downloader
    obs-studio
    pavucontrol
    video-trimmer
    vlc

    ## Office
    gnome-calculator

    ## Communication
    telegram-desktop

    ## Utility
    antigravity
    blueman # Bluetooth manager GUI
    dconf-editor
    gnome-disk-utility
    popsicle
    mission-center # GUI resources monitor
    zenity
    customPkgs.fan-control # CPU Fan Control GUI

    ## Level editor
    ldtk
    tiled

    ## X11 libraries
    libx11
    libxcursor
    libxrandr
    libxi
    libxcb
    libxkbcommon
    libGL
  ];
}
