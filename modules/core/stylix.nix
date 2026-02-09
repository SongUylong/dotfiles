{ pkgs, ... }:
{
  stylix = {
    enable = true;

    # Color scheme (using base16)
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Wallpaper (optional - comment out if you don't want one)
    image = ../../wallpapers/wallpaper.png;

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

    # Which apps to theme
    targets = {
      gtk.enable = true;
      gnome.enable = true;
      hyprland.enable = true;
      rofi.enable = true;
      waybar.enable = true;
      firefox.enable = true;
      neovim.enable = true;
      tmux.enable = true;
      zellij.enable = true;
      fzf.enable = true;
      lazygit.enable = true;
      bat.enable = true;
      btop.enable = true;
      dunst.enable = true;
      mako.enable = true;
      vim.enable = true;
      vscode.enable = true;
      wezterm.enable = true;
      swaylock.enable = true;
    };
  };
}
