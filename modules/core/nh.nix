{ username, ... }:
{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      # Run at 3am daily rather than shortly after boot to avoid adding
      # disk I/O pressure during startup.
      dates = "03:00";
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/home/${username}/dotfiles";
  };
}
