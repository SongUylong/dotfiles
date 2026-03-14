{ pkgs, ... }:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
      build-use-substitutes = true;
      keep-outputs = true;
      keep-derivations = true;
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    alsa-lib
  ];

  time.timeZone = "Asia/Phnom_Penh";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_COLLATE = "C";
  };
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
  ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
  programs.nix-ld.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
