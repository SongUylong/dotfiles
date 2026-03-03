{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "fan-control";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    
    # Install script
    cp fan-control.sh $out/bin/fan
    chmod +x $out/bin/fan
    
    # Wrap with polkit in PATH
    wrapProgram $out/bin/fan \
      --prefix PATH : ${pkgs.polkit}/bin
  '';

  meta = with pkgs.lib; {
    description = "Simple CLI for controlling CPU fan speed";
    platforms = platforms.linux;
  };
}
