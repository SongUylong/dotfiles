{ pkgs, ... }:
{
  stylix = {
    enable = true;

    # Color scheme (Catppuccin Mocha)
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    
    # Wallpaper
    image = ../../wallpapers/wallpaper.png;
    
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
        package = pkgs.maple-mono-NF;
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
        terminal = 12;
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

    # Which apps to theme (supported by Stylix)
    targets = {
      # Desktop environment
      gtk.enable = true;
      gnome.enable = true;
      hyprland.enable = true;
      
      # Launchers and bars
      rofi.enable = true;
      waybar.enable = true;
      
      # Terminals
      wezterm.enable = true;
      
      # Editors
      neovim.enable = true;
      vim.enable = true;
      vscode.enable = true;
      
      # Shell tools
      tmux.enable = true;
      fzf.enable = true;
      
      # Notifications and locks
      mako.enable = true;
      swaylock.enable = true;
      
      # Browsers
      firefox.enable = true;
    };
  };
}
