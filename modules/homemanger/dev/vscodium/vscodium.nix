{ pkgs, ... }:
{
  stylix.targets.vscode.enable = true;

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
  };
}
