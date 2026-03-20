{ pkgs, ... }:
{
  home.packages = with pkgs; [ direnv ];

  programs.direnv = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
  };
}
