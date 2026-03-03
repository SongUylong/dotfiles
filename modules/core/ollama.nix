{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama.override {
      # Build with CUDA support and Pascal architecture for GTX 1060
      acceleration = "cuda";
      cudaArches = [
        "60" # Pascal (GP100)
        "61" # Pascal (GTX 1060, 1070, 1080, Titan X)
        "70" # Volta (V100)
        "75" # Turing (RTX 20 series)
        "80" # Ampere (A100)
        "86" # Ampere (RTX 30 series)
        "89" # Ada Lovelace (RTX 40 series)
        "90" # Hopper (H100)
      ];
    };
    openFirewall = true;
  };
}
