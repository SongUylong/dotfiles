{ pkgs, ... }:
{
  systemd.user.services.tmux = {
    Unit = {
      Description = "tmux default session";
      Documentation = "man:tmux(1)";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "forking";
      Environment = "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
      ExecStart = "${pkgs.tmux}/bin/tmux -f %h/.config/tmux/tmux.conf start-server";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-server";
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
