{ pkgs, ... }:
{
  stylix = {
    enable = true;

    # Color scheme (Catppuccin Mocha)
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Wallpaper
    image = ../../wallpapers/city-horizon.jpg;

    # Force dark theme
    polarity = "dark";

    # Cursor theme
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    # Font configuration
    fonts = {
      monospace = {
        package = pkgs.maple-mono.NF;
        name = "Maple Mono NF";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 12;
        terminal = 10;
        desktop = 10;
        popups = 10;
      };
    };

    # Opacity
    opacity = {
      applications = 1.0;
      terminal = 0.9;
      desktop = 1.0;
      popups = 0.9;
    };

    icons = {
      enable = true;
      package = pkgs.tela-circle-icon-theme;
      dark = "Tela-circle-dark";
      light = "Tela-circle-light";
    };
    # Which apps to theme (supported by Stylix)
    # Note: Most targets are Home Manager only and configured in respective HM modules
    targets = {
      # Desktop environment (system-level)
      gtk.enable = true;
      grub.enable = false; # Disable GRUB theming - using custom Star Wars theme
    };
  };
}
