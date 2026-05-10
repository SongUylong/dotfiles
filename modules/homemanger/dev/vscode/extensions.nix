{ pkgs, ... }:
{
  programs.vscode.profiles.default = {
    extensions = with pkgs.vscode-extensions; [
      ## AI
      github.copilot
      github.copilot-chat

      ## Languages
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      # ms-python.python
      llvm-vs-code-extensions.vscode-clangd
      ziglang.vscode-zig
      tamasfe.even-better-toml
      golang.go

      ## Color scheme
      catppuccin.catppuccin-vsc
      catppuccin.catppuccin-vsc-icons
    ];
  };
}
