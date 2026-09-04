# 🌌 Dark Niri Dotfiles

Welcome to **Dark Niri**, a curated, Wayland-native desktop environment configuration centered around the [Niri](https://github.com/YaLTeR/niri) scrollable-tiling window manager. 

This repository contains everything you need to bootstrap a fully functional, highly aesthetic, and keyboard-driven desktop experience.

---

## 📁 Repository Structure

The folder structure is designed to map directly to your `~/.config/` directory.

```text
DARK_NIRI/
├── niri/                       # Main compositor configuration
│   ├── config.kdl              # Keybindings, window rules, layouts, inputs
│   └── startup.sh              # Autostart script (Bar, Notifications, Wallpaper)
├── fuzzel/                     # Application launcher
│   └── fuzzel.ini              # Theming and layout settings
├── quickshell/                 # Status Bar (QtQuick based)
│   ├── shell.qml               # Main panel and layout definitions
│   └── components/             
│       └── Clock.qml           # Live clock module
├── mako/                       # Notification daemon
│   └── config                  # Colors, fonts, and borders
├── deploy.sh                   # Safely symlinks configs to ~/.config
├── uninstall.sh                # Removes symlinks and restores backups
├── keybindings-docs.md         # Detailed cheat sheet for keyboard shortcuts
└── README.md                   # You are here!
```

---

## 🧩 Components Overview

This setup uses modern, Wayland-native tools selected for their speed, customizability, and cohesive aesthetic.

### 1. Niri (Window Manager)
Niri is a scrollable-tiling Wayland compositor. Instead of managing complex grids of windows, Niri opens windows in a continuous horizontal strip.
- **Aesthetics**: Configured with 16px gaps, rounded corners, and a dark purple focus ring.
- **Workflow**: Heavily relies on the `Super` key. 
- **Documentation**: See [`keybindings-docs.md`](keybindings-docs.md) for a full breakdown of the layout and shortcuts.

### 2. Quickshell (Status Bar)
A highly modular shell built on QML. It provides a beautiful top panel out of the box.
- Features a live clock.
- Easily expandable by dropping new `.qml` widgets into the `components/` folder.

### 3. Fuzzel (App Launcher)
A very fast Wayland-native application launcher. 
- Bound to `Super + Space`.
- Themed in `#1a1b26` (Dark Tokyo Night style) with `#7aa2f7` borders to match the system.

### 4. Mako (Notifications)
A lightweight Wayland notification daemon.
- Displays notifications in the corner of your screen.
- Styled with rounded borders and a matching dark palette.

---

## 🚀 Installation & Deployment

We have included automated scripts to safely link these dotfiles to your system.

### Dependencies
Before deploying, ensure you have the required software installed on your Linux distribution:
- `niri`
- `fuzzel`
- `quickshell`
- `mako`
- `alacritty` (Default terminal emulator)
- `brightnessctl` (For backlight control)
- `wireplumber` (Provides `wpctl` for audio control)

### Deploying
1. Clone or download this repository to your home directory (e.g. `~/DARK_NIRI`).
2. Run the deployment script:
   ```bash
   cd ~/DARK_NIRI
   ./deploy.sh
   ```
   *Note: This script will automatically back up any existing configurations in your `~/.config` folder to `.bak` files before creating symlinks.*

3. Start Niri by running `niri-session` from a TTY, or selecting "Niri" in your display manager (like GDM or SDDM).

### Uninstalling / Reverting
If you wish to test these dotfiles and later revert to your previous setup, simply run:
```bash
cd ~/DARK_NIRI
./uninstall.sh
```
This will remove the symlinks and restore your original `.bak` backups.

---

## 🎨 Customization

- **Wallpaper:** To set a wallpaper, install `swaybg`, open `niri/startup.sh`, and uncomment the `swaybg` line, replacing the path with your image.
- **Terminal:** If you prefer a terminal other than Alacritty, open `niri/config.kdl` and `fuzzel/fuzzel.ini` and change the `alacritty` commands to your preferred terminal (e.g., `kitty`, `foot`).
