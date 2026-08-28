# ❄️ NixOS & Home Manager Dotfiles

Reproducible, declarative desktop and laptop configuration powered by **Nix Flakes**, **NixOS**, and **Home Manager**.

---

## 🖥️ System Architecture

- **OS:** NixOS (Unstable / Stable Channels)
- **Flake Setup:** Modular multi-host configuration (`hosts/desktop`, `hosts/laptop`)
- **Window Manager / Compositor:** Wayland / Hyprland / GNOME
- **Theming:** Stylix unified system-wide styling
- **Shell & Tools:** Zsh, Tmux, Yazi file manager, Neovim / OpenCode
- **AI Integration:** Local Ollama service integration (`modules/core/ollama.nix`)

---

## 📁 Repository Structure

```
├── flake.nix                   # Flake entry point & system outputs
├── flake.lock                  # Pinned Nix package inputs
├── hosts/
│   ├── desktop/                # Desktop machine configuration
│   └── laptop/                 # Laptop machine configuration & power saving
└── modules/
    ├── core/                   # System-level modules (bootloader, audio, networking, ollama, virtualization)
    └── homemanger/             # User-space configurations (cli, packages, tmux, yazi, browsers)
```

---

## 🚀 Installation & Deployment

> ⚠️ **Caution:** Review hardware configurations before applying to your system.

```bash
# Clone the repository
git clone https://github.com/SongUylong/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Rebuild desktop system
sudo nixos-rebuild switch --flake .#desktop

# Or rebuild laptop system
sudo nixos-rebuild switch --flake .#laptop
```

---

## 👤 Author

**Song Uylong** ([@SongUylong](https://github.com/SongUylong))
