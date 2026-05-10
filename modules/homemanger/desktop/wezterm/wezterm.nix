{ config, lib, ... }:
{
  # Stylix also writes `xdg.configFile."wezterm/wezterm.lua"` with `text = mkForce`.
  # That merges with this symlink and leaves both `text` and `source` set; activation
  # uses the generated text, so your repo lua never loads. Disable the target and
  # manage WezTerm entirely from the symlinked file (or use programs.wezterm.extraConfig
  # with Stylix enabled — extraConfig must return a table for Stylix's wrapper).
  stylix.targets.wezterm.enable = false;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."wezterm/wezterm.lua".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/modules/homemanger/desktop/wezterm/wezterm.lua"
  );
}
