{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    nerd-fonts.symbols-only
    twemoji-color-font
    noto-fonts-color-emoji
    noto-fonts
    noto-fonts-cjk-sans
    fantasque-sans-mono
    maple-mono-custom
  ];

  # Stylix handles GTK theming automatically
}
