{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      # Theme handled by Stylix
    };
    extraPackages = with pkgs.bat-extras; [
      batman
      batpipe
      # batgrep
      # batdiff
    ];
  };
}
