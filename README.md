# 🌌 Dark Niri

<div align="center">

![Niri](https://img.shields.io/badge/Compositor-Niri%20Wayland-7c4dff?style=for-the-badge)
![QuickShell](https://img.shields.io/badge/Shell-QuickShell%20QML-7aa2f7?style=for-the-badge)
![Theme](https://img.shields.io/badge/Theme-Tokyo%20Night-1a1b26?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-9ece6a?style=for-the-badge)

**A high-performance, keyboard-driven, Wayland-native desktop environment centered around the Niri scrollable-tiling window manager, featuring a custom QuickShell status bar, integrated Control Center, and Tokyo Night aesthetic.**

[Features](#-key-features) • [Quick Start](#-quick-start) • [Keybindings](#-essential-keybindings) • [Documentation Hub](#-documentation-hub)

</div>

---

## 🎯 Overview

**Dark Niri** is a curated desktop configuration combining the continuous horizontal workflow of [Niri](https://github.com/YaLTeR/niri) with a rich, interactive QtQuick/QML desktop shell powered by [QuickShell](https://github.com/outfoxxed/quickshell).

- **Supported Compositor**: Niri (Wayland)
- **Primary Distribution**: Arch Linux (systemd & Wayland stack)
- **Design Philosophy**: Minimalist dark glassmorphism (Tokyo Night `#1a1b26`), keyboard-first window management, and zero bloat.

---

## ✨ Key Features

- 📜 **Scrollable Column Tiling**: Infinite horizontal workspace ribbon with 33.3%, 50%, and 66.7% preset column widths.
- 🐚 **Custom QuickShell Top Bar**: 55px bar with 12 modular widgets (Workspaces, Clock, Hardware Monitor, Media, Network, Bluetooth, Audio, Mic, Brightness, Battery, Screencast, Control Center).
- ⚙️ **Integrated Control Center (`Settings.qml`)**: 2,936 lines of modular QML providing quick toggles, master volume/brightness sliders, and interactive modals.
- 📶 **Wi-Fi Manager with WPS Support**: Scans networks, prompts for credentials, and interrogates D-Bus AP flags for instant WPS pairing.
- 🖼️ **Modular HTML/Web Wallpaper Engine**: Hardware-accelerated background engine powered by `gtk4-layer-shell` and `webkitgtk-6.0`. Renders interactive HTML5, CSS3, Canvas, and WebGL themes (`cyber-city`, `aurora`, `cyber-matrix`, `particles`, `waves`) alongside user pictures and videos with live real-time particle, parallax, lighting, weather, and HUD clock customization.
- 📊 **Real-Time Hardware Telemetry**: Live CPU %, thermals, fan RPM, RAM usage, persistent daily/monthly network data usage, AMD iGPU, and NVIDIA dGPU telemetry.
- 🎵 **MPRIS Media Player**: Album art preview, hover controls, previous/play/pause/next, and position seeking.
- 📹 **Screencasting Controller**: Region screen recording with live pulse indicator and pause/resume capabilities (`wf-recorder`).
- 🔔 **Interactive Notification Center**: Backed by `mako` with per-item dismissal and batch clear.
- 📋 **Clipboard History**: `Super + V` powered by `cliphist`, `wl-clipboard`, and `rofi`.

---

## 🚀 Quick Start

### 1. Install Dependencies (Arch Linux)
```bash
sudo pacman -S --needed \
    niri rofi-wayland mako alacritty \
    pipewire wireplumber libpulse playerctl \
    networkmanager bluez bluez-utils \
    brightnessctl power-profiles-daemon lm_sensors upower \
    webkitgtk-6.0 gtk4-layer-shell wf-recorder grim slurp wl-clipboard cliphist \
    ttf-inter ttf-nerd-fonts-symbols papirus-icon-theme python python-gobject git

# Enable Bluetooth, Wi-Fi, and Power Profile daemons
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon

# Install QuickShell from AUR (e.g. using yay)
yay -S --needed quickshell-git
```

### 2. Deploy Dotfiles
```bash
git clone https://github.com/Aryan-Harmalkar/DARK_NIRI.git ~/DARK_NIRI
cd ~/DARK_NIRI
chmod +x deploy.sh uninstall.sh
./deploy.sh
```

---

## ⌨️ Essential Keybindings

| Shortcut | Action | Command / Target |
| :--- | :--- | :--- |
| `Super + Return` | Open Terminal | `alacritty` |
| `Super + Space` | Application Launcher | `rofi -show drun` |
| `Super + V` | Clipboard History | `cliphist list \| rofi` |
| `Alt + F` | Close Window | `close-window` |
| `Super + F` | Maximize Column Width | `maximize-column` |
| `Super + Shift + F` | Fullscreen Window | `fullscreen-window` |
| `Super + Left / Right` | Focus Column Left / Right | `focus-column-left/right` |
| `Super + Up / Down` | Focus Window Up / Down | `focus-window-up/down` |
| `Super + 1 .. 5` | Switch Workspace 1 to 5 | `focus-workspace 1..5` |
| `Super + Shift + 1 .. 5`| Move Column to Workspace | `move-column-to-workspace 1..5` |
| `Print` | Area Screenshot | `grim -g "$(slurp)"` |
| `Super + Print` | Fullscreen Screenshot | `grim` |
| `Super + Shift + /` | Show Hotkey Overlay | `show-hotkey-overlay` |

---

## 📚 Documentation Hub

The complete documentation suite is organized in the [`docs/`](docs/) directory:

### 🟢 [Simple & Beginner Guides (`docs/simple/`)](docs/simple/README.md)
- 🚀 [**Getting Started**](docs/simple/GETTING_STARTED.md): 3-step setup and logging in for the first time.
- ⌨️ [**Keyboard Shortcuts Cheat Sheet**](docs/simple/KEYBOARD_SHORTCUTS.md): Essential daily shortcuts explained simply.
- 🎛️ [**Top Bar & Control Center**](docs/simple/BAR_AND_CONTROLS.md): Guide to Wi-Fi, Bluetooth, volume, and wallpaper settings.
- 🎨 [**How to Customize**](docs/simple/HOW_TO_CUSTOMIZE.md): Easy instructions to change wallpapers, terminal, and keys.
- ❓ [**Common Problems & Fixes**](docs/simple/COMMON_PROBLEMS.md): Quick solutions for everyday desktop issues.

### 🔵 [Technical & Developer Reference (`docs/complex/`)](docs/complex/README.md)
- 🏗️ [**Architecture & Protocols**](docs/complex/ARCHITECTURE.md)
- 📁 [**Complete File Structure**](docs/complex/FILE_STRUCTURE.md)
- 🌟 [**Feature Matrix**](docs/complex/FEATURES.md)
- 📦 [**Package Manifest**](docs/complex/PACKAGES.md)
- 🔗 [**Dependency Matrix**](docs/complex/DEPENDENCIES.md)
- 📜 [**Niri Deep Dive**](docs/complex/NIRI.md)
- 🐚 [**QuickShell Architecture**](docs/complex/QUICKSHELL.md)
- 🌐 [**HTML/Web Wallpaper Engine**](docs/wallpapers.md)
- 📊 [**System Telemetry Subsystem**](docs/complex/SYSTEM_MONITOR.md)
- 🎵 [**Media Player Subsystem**](docs/complex/MEDIA.md)
- ⚙️ [**Control Center Details**](docs/complex/SETTINGS.md)
- 📶 [**Network & WPS Subsystem**](docs/complex/NETWORK.md)
- 🔵 [**Bluetooth & Audio Profiles**](docs/complex/BLUETOOTH.md)
- 🔒 [**Security Audit**](docs/complex/SECURITY.md)
- 🌐 [**Portability Audit**](docs/complex/PORTABILITY.md)
- 💻 [**Developer Guidelines**](docs/complex/DEVELOPMENT.md)

---

## 🛠️ Uninstallation & Backup Recovery

If you ever want to revert back to your previous setup:
```bash
cd ~/DARK_NIRI
./uninstall.sh
```
This cleanly removes all symlinks and restores your previous `.config` backups automatically.
