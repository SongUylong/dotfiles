# Dotfiles (Fedora + Hyprland + editors)

Fedora Workstation with **Hyprland**, **Waybar**, **Rofi**, **SwayNC**, plus **Neovim (LazyVim)**, **WezTerm**, **Cursor / VS Code / Antigravity** shared settings, and optional **macOS-only** configs (SketchyBar, AeroSpace, borders) kept for when you sync the same repo from a Mac.

## First-time install (Fedora)

1. Clone to `~/dotfiles` (paths in `hyprlock` and scripts assume this).

2. Run the installer (RPMs from **`packages-fedora-base.txt`** plus, by default, **COPR** packages from **`packages-fedora-copr.txt`** — Hyprland, WezTerm, `swww`, Bibata are not in stock Fedora). Then it symlinks `home/.config/*`, `bin/*`, and runs `scripts/sync-editors`:

   ```bash
   cd ~/dotfiles
   chmod +x install-fedora.sh
   ./install-fedora.sh
   ```

   - **`dnf`** uses **`--skip-unavailable`** so one bad package name does not abort the whole run.
   - **Skip COPR** (only base repos): `ENABLE_COPR=0 ./install-fedora.sh`
   - If a COPR fails to enable (network, policy), install the missing pieces manually after reading the comments in `packages-fedora-copr.txt`.
   - **WezTerm:** with `wezfurlong/wezterm-nightly` enabled, run `sudo dnf install wezterm` (the package is named **`wezterm`**, not `wezterm-nightly`). Or use Flathub: `flatpak install flathub org.wezfurlong.wezterm`.
   - **App launcher (Super+Space):** needs **`rofi-wayland`** (Wayland fork). Stock **`rofi`** is X11-only and will not show `drun` on Hyprland. The installer pulls `rofi-wayland` from Fedora’s repos.
   - **Nerd Fonts:** by default the installer enables **`komapro/nerd-fonts`** and **`aquacash5/nerd-fonts`** and installs **`jetbrainsmono-nerd-font`** + **`cascadia-code-nerd-fonts`** (Caskaydia Cove for editors). To skip: `ENABLE_NERD_FONTS=0 ./install-fedora.sh`.

3. Optional Hyprland helpers (clipboard, mounts, etc.):

   ```bash
   sudo dnf install -y udiskie poweralertd || true
   ```

4. Log out and start a **Hyprland** session, or run `Hyprland` from a TTY.

### Why the login screen still looks like Fedora / GNOME

**GDM** (the graphical login manager) is separate from your desktop. Until you sign in, you are still in Fedora’s **default greeter** (Workstation look, GNOME session list, etc.). **Hyprland only starts after you log in** — it does not replace the boot/login UI.

- To land in Hyprland every time: pick **Hyprland** in the session menu (gear) before entering your password, or set a default session (see earlier README notes: `/var/lib/AccountsService/users/$USER` with `Session=hyprland`).
- To **change how GDM looks** (theme, dark mode), you customize **GDM** (GTK/shell resources for the `gdm` user), not Hyprland — that is a separate, optional tweak.
- To **skip the greeter** entirely (**automatic login**): run **`sudo ~/dotfiles/scripts/enable-gdm-autologin YOURUSERNAME`** (use your Linux login name, usually the same as `$USER`). It backs up `/etc/gdm/custom.conf`, sets `AutomaticLoginEnable=true` and `AutomaticLogin=…`, then **reboot** (or `sudo systemctl restart gdm.service` — you will be kicked off the graphical session). Ensure your **default graphical session is Hyprland** (`Session=hyprland` in `/var/lib/AccountsService/users/YOURUSERNAME` or pick it once in the session menu before enabling autologin). **Security:** anyone who can turn the machine on is logged in as that user — avoid on shared or laptops you do not control. To turn off: **`sudo ~/dotfiles/scripts/disable-gdm-autologin`**. Optional: **`ENABLE_GDM_AUTOLOGIN=1 ./install-fedora.sh`** runs the enable step after packages (still requires `sudo`).

### Editors (Cursor, VS Code, Antigravity)

- Canonical JSON lives under **`editors/`**: `settings.shared.json`, `keybindings.json`, `overrides/{cursor,vscode,antigravity}.json`.
- **`install-fedora.sh`** runs **`scripts/sync-editors`**, which merges those into **`editors/dist/settings.*.json`** and symlinks them plus keybindings into:
  - **Linux:** `~/.config/Cursor/User`, `~/.config/Code/User`, `~/.config/Antigravity/User`
  - **macOS:** `~/Library/Application Support/.../User` (see `scripts/sync-editors`)
- Override install locations with `CURSOR_USER_DIR`, `VSCODE_USER_DIR`, `ANTIGRAVITY_USER_DIR` if your distro uses different paths.
- Install extensions from `editors/extensions.txt`:

  ```bash
  INSTALL_EDITOR_EXTENSIONS=1 ./install-fedora.sh
  # or:
  ./scripts/sync-editors --install-extensions
  ```

- To skip editor linking: `SKIP_SYNC_EDITORS=1 ./install-fedora.sh`
- **Antigravity (RPM)** on Fedora/RHEL-style systems: repo file is **`extras/yum.repos.d/antigravity.repo`**. Install with:
  `INSTALL_ANTIGRAVITY=1 ./install-fedora.sh` (adds `/etc/yum.repos.d/antigravity.repo`, `dnf makecache`, `dnf install antigravity`). Settings still come from **`scripts/sync-editors`** → `~/.config/Antigravity/User`.

### Neovim

- Config: **`home/.config/nvim/`** (LazyVim-style `init.lua`, `lua/`, lockfiles).
- Run `nvim` once; run `:Lazy` if plugins need syncing. Build tools (`gcc`, `cmake`, …) are listed in `packages-fedora.txt` for native LSP/tools.

### Zsh (Zinit + Powerlevel10k)

- **`home/.config/zsh/`** — `config.zsh`, `.zshrc`, `.p10k.zsh`.
- Installer links **`~/.zshrc`** and **`~/.p10k.zsh`** to those files.
- On first login, **Zinit** clones plugins (needs **git** and network).

### macOS snapshot

- The folder **`dotfiles-macos/`** is an older zip extract; the live configs are merged into **`home/.config/`**, **`editors/`**, **`scripts/`**, and **`codeUtility/`**. You can delete `dotfiles-macos/` once you are satisfied nothing is missing.

## Layout

| Path | Purpose |
|------|---------|
| `home/.config/hypr/` | Hyprland, hypridle, hyprlock |
| `home/.config/waybar/` | Waybar JSON + CSS |
| `home/.config/zsh/` | Zinit + p10k + `config.zsh` |
| `home/.config/nvim/` | Neovim (LazyVim) |
| `home/.config/wezterm/`, `neovide/`, `opencode/` | Terminals / editors |
| `home/.config/tmux/`, `tmuxinator/`, `yazi/`, `zellij/` | CLI / multiplexers |
| `home/.config/fastfetch/` | Fastfetch |
| `home/.config/sketchybar/`, `aerospace/`, `borders/` | Mainly **macOS** (harmless on Linux) |
| `editors/` | Shared VS Code–family settings + overrides |
| `scripts/sync-editors` | Merge + symlink editor configs |
| `codeUtility/.agents/skills/` | Agent skills / docs |
| `bin/` | Helper scripts → `~/.local/bin` |
| `wallpapers/` | Backgrounds |

## Tweaks

- **Monitors:** `~/.config/hypr/monitors.conf`
- **Hyprland wallpaper / lock:** `hypr/hyprlock.conf` (`$HOME/dotfiles/...`)
- **Waybar keyboard widget:** hardware-specific; edit `waybar/config` if needed

## `grimblast`

`bin/grimblast` is a small **grim + slurp** shim for screenshot scripts.

## Legacy NixOS

The old Nix flake was removed; use Git history if you need it.
