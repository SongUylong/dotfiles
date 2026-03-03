{
  inputs,
  pkgs,
  system,
  ...
}:
{
  maple-mono-custom = pkgs.callPackage ./maple-mono { inherit inputs; };
  fan-control = pkgs.callPackage ./fan-control { };
}
