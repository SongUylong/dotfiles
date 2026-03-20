{ ... }:
{
  imports = [
    ./cli # Command line tools
    ./dev # Development tools
    ./desktop # Desktop environment
    ./apps # Applications
    ./system # System utilities
    ./../../scripts/scripts.nix # Personal scripts
  ];
}
