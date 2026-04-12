{
  inputs,
  pkgs,
  system,
  ...
}:
{
  maple-mono-custom = pkgs.callPackage ./maple-mono { inherit inputs; };
  fan-control = pkgs.callPackage ./fan-control { };

  pnpm = pkgs.callPackage "${pkgs.path}/pkgs/development/tools/pnpm/generic.nix" {
    version = "10.33.0";
    hash = "sha256-v8wby60nmxOlFsRGp1s8WLaQS0XVehlRQRAV5Qt1GoA=";
  };
}
