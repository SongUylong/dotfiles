{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Compiler
    gcc

    ## Lsp
    nixd # nix

    ## formating
    shfmt
    treefmt
    nixfmt

    ## Python
    python3
    python312Packages.ipython

    ## Node.js
    nodejs_22 # or nodejs_20, nodejs_18
    # nodePackages.npm  # included with nodejs
    # nodePackages.yarn
    nodePackages.pnpm
    bun

    ## Prisma
    nodePackages.prisma
    prisma-engines_6

    ## AI Tools
    opencode

    ## Terminal multiplexer
    zellij

    ## Code Editors
    code-cursor
    zed-editor

    ## Rust
    rustc
    cargo
  ];

  home.sessionVariables = {
    PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING = "1";
    PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines_6}/bin/schema-engine";
    PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines_6}/bin/query-engine";
    PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines_6}/lib/libquery_engine.node";
    PRISMA_FMT_BINARY = "${pkgs.prisma-engines_6}/bin/prisma-fmt";
  };
}
