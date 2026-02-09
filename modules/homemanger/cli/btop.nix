{ pkgs, ... }:
{
  programs.btop = {
    enable = true;

    settings = {
      # Theme handled by Stylix
      update_ms = 500;
      rounded_corners = false;
    };
  };

  home.packages = with pkgs; [ nvtopPackages.intel ];
}
