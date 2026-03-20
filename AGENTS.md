# Agent Guidelines for NixOS Dotfiles

This repository contains NixOS flake configurations with Home Manager modules, shell scripts, and Hyprland/Wayland setup.

## Project Structure

```
.
├── flake.nix              # Flake entry point with host/module definitions
├── treefmt.toml           # Code formatting configuration
├── hosts/                 # Host-specific NixOS configs (desktop/laptop)
│   ├── desktop/
│   └── laptop/
├── modules/               # Modular configuration components
│   ├── core/              # Core system services (NixOS modules)
│   └── homemanger/        # Home Manager user configurations
│       ├── cli/           # CLI tools
│       ├── dev/           # Development tools (git, nvim, vscodium)
│       ├── desktop/       # Desktop environment (hyprland, waybar, rofi)
│       ├── apps/          # Application configs
│       └── system/        # System utilities (zsh, ssh, etc.)
├── scripts/              # Shell scripts
│   └── scripts/          # User scripts deployed via Nix
└── shared/               # Shared configurations
```

## Build/Lint/Test Commands

### Format All Code
```bash
treefmt
```
Formats Nix files with `nixfmt` (80-char width, strict) and shell scripts with `shfmt` (4-space indent, case indent, simplify-range).

### Test Flake Configuration
```bash
# Check flake syntax
nix flake check

# Show the evaluated configuration (desktop host)
nix eval .#nixosConfigurations.desktop.config.system.build.toplevel --json

# Build without switching
nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# Dry run rebuild
sudo nixos-rebuild dry-build --flake .#desktop
```

### Apply Configuration
```bash
# Build and switch (NixOS)
sudo nixos-rebuild switch --flake .#desktop

# For laptop host
sudo nixos-rebuild switch --flake .#laptop
```

### Update Dependencies
```bash
# Update flake inputs
nix flake update

# Update home-manager channels
home-manager lock
```

### Shellcheck (Bash Scripts)
```bash
shellcheck scripts/scripts/*.sh
```

## Code Style Guidelines

### Nix Conventions

**Formatting:**
- Use `nixfmt` with strict mode (`-sv -w 80`) - 80 character line width
- Always use 2 spaces for indentation
- One blank line between let-in blocks and main body
- Attrsets: align `=` for related entries, no trailing comma on last item

**Imports:**
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ./relative/path.nix
    inputs.nur.overlays.default
  ];
}
```

**Overlays:**
```nix
final: prev:
(import ../../pkgs {
  inherit inputs pkgs;
  inherit (prev) system;
})
```

**Package Lists:**
```nix
home.packages = with pkgs; [
  package-name
  another-package
];
```

**Attribute Sets:**
```nix
programs.git = {
  enable = true;
  settings = {
    user.name = "username";
    user.email = "email@example.com";
  };
};
```

**Functions:**
```nix
# Simple function
mkScript = name: {
  name = name;
  value = pkgs.writeScriptBin name (builtins.readFile (./path + "/${name}"));
};

# With pattern matching
mkScript = name: {
  name = name;
  value = pkgs.writeScriptBin (builtins.replaceStrings [".sh"] [""] name) (...);
};
```

**Module System:**
```nix
{ pkgs, inputs, username, ... }:
{
  # Module options and config
  programs.git.enable = true;

  # XDG config files
  xdg.configFile."app/config".text = ''
    content here
  '';

  # Conditional config
  imports = lib.optionals (host == "desktop") [
    ./desktop-specific.nix
  ];
}
```

### Shell Script Conventions

**Shebang and Mode:**
```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Formatting (shfmt):**
- 4-space indent
- Case indents
- Simplify ranges
- Space after redirection (`> /dev/null` not `>/dev/null`)

**Variable Naming:**
- Lowercase with underscores: `script_dir`, `output_file`
- Constants UPPERCASE: `MAX_RETRIES=5`
- Quote variables: `"$variable"` not `$variable`
- Use command substitution: `$(command)` not `` `command` ``

**Functions:**
```bash
function_name() {
    local arg1="$1"
    local result

    result="$(some_command "$arg1")"
    echo "$result"
}
```

**Error Handling:**
```bash
# Check command existence
if ! command -v program &>/dev/null; then
    echo "Error: program not found" >&2
    exit 1
fi

# Check required arguments
[ $# -eq 0 ] && { echo "Usage: $0 <arg>" >&2; exit 1; }
```

**Logging Patterns:**
```bash
readonly OK="[${GREEN}OK${RESET}]"
readonly ERROR="[${RED}ERROR${RESET}]"
echo -e "${INFO}Starting process..."
```

### General Guidelines

**Paths:**
- Use relative paths for intra-repo imports
- Always use `builtins.readFile` or `pkgs.writeScriptBin` for inline file content
- XDG base directories: `$XDG_CONFIG_HOME` or `~/.config`

**Security:**
- Never hardcode secrets; use `inputs` or environment variables
- Quote all variables used in command arguments
- Use `&>/dev/null` for suppressing output when appropriate

**Module Organization:**
- Keep modules focused: one concern per file
- Use descriptive file names: `hyprland.nix`, `git.nix`, not `module1.nix`
- Group related configs under subdirectories
- Document non-obvious configurations with comments

**Git:**
- Commit messages: imperative mood ("Add hyprland config" not "Added")
- Group related changes in single commits

## Hyprland/Wayland Specific

**Window Manager Config:**
- Located in `modules/homemanger/desktop/hyprland/`
- Keybinds: use `$mainMod` prefix
- Window rules: specific apps first, then general rules
- Environment variables in `exec-once.nix`

**Workspace Layout:**
- Hyprland monitors config defines workspace assignments
- Use `hyprctl` for runtime commands

## Common Patterns

**Conditional Imports:**
```nix
imports = [
  ./base.nix
] ++ lib.optionals (host == "desktop") [
  ./desktop.nix
] ++ lib.optionals pkgs.stdenv.isLinux [
  ./linux.nix
];
```

**Read Directory (dynamic imports):**
```nix
scriptDir = ./scripts;
scriptEntries = builtins.readDir scriptDir;
regularFiles = builtins.filter (name: scriptEntries.${name} == "regular") (
  builtins.attrNames scriptEntries
);
```

**Write Script to Bin:**
```nix
pkgs.writeScriptBin "script-name" (builtins.readFile ./script.sh)
```

## Quick Reference

| Task | Command |
|------|---------|
| Format code | `treefmt` |
| Rebuild desktop | `sudo nixos-rebuild switch --flake .#desktop` |
| Check flake | `nix flake check` |
| Update deps | `nix flake update` |
| Dry run | `sudo nixos-rebuild dry-build --flake .#desktop` |
