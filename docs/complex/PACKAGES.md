# 📦 Package & Dependency Catalog

This document categorizes all software packages required to run, configure, and maintain the **Dark Niri** desktop environment.

---

## 1. Package Classification

### 1.1 Core Compositor & Shell
| Package Name | Source | Purpose | Required | What Breaks If Missing |
| :--- | :--- | :--- | :---: | :--- |
| `niri` | Official / AUR | Wayland scrollable-tiling compositor | **Yes** | Entire desktop fails to start |
| `quickshell` | AUR (`quickshell-git`) | QtQuick/QML desktop shell framework | **Yes** | Status bar and control center missing |
| `rofi-wayland` | Official | Wayland-native application launcher & prompt | **Yes** | App launcher, clipboard, reminder, shutdown break |
| `mako` | Official | Wayland notification daemon | **Yes** | Notifications and OSD popups missing |
| `alacritty` | Official | Default terminal emulator | **Yes** | `Mod+Return` terminal keybind fails |

### 1.2 Audio & Media Subsystem
| Package Name | Source | Purpose | Required | What Breaks If Missing |
| :--- | :--- | :--- | :---: | :--- |
| `pipewire` | Official | Modern audio server | **Yes** | Audio playback & recording fail |
| `wireplumber` | Official | PipeWire session manager (provides `wpctl`) | **Yes** | Audio volume, mic mute, and OSD break |
| `libpulse` | Official | PulseAudio client libraries (provides `pactl`) | **Yes** | Bluetooth audio profile switching breaks |
| `playerctl` | Official | MPRIS command-line controller | **Yes** | Media player pill & controls fail |

### 1.3 Network & Bluetooth Subsystem
| Package Name | Source | Purpose | Required | What Breaks If Missing |
| :--- | :--- | :--- | :---: | :--- |
| `networkmanager`| Official | Network management daemon (provides `nmcli`)| **Yes** | Wi-Fi widget, scanning, and connections break |
| `bluez` | Official | Bluetooth protocol stack daemon | **Yes** | Bluetooth cannot function |
| `bluez-utils` | Official | Bluetooth CLI tools (provides `bluetoothctl`) | **Yes** | Bluetooth widget & pairing modal break |

### 1.4 Hardware Monitoring & Control
| Package Name | Source | Purpose | Required | What Breaks If Missing |
| :--- | :--- | :--- | :---: | :--- |
| `brightnessctl` | Official | Backlight level controller | **Yes** | Brightness slider & OSD break |
| `power-profiles-daemon` | Official | D-Bus power profile daemon (`powerprofilesctl`)| **Yes** | Power profile switcher fails (falls back to sysfs)|
| `lm_sensors` | Official | Hardware monitoring sensors (provides `sensors`)| Optional | CPU thermals/fan speeds fallback to 0 |
| `nvidia-utils` | Official | NVIDIA driver utilities (provides `nvidia-smi`)| Optional | NVIDIA dGPU metrics missing on hybrid systems |
| `upower` | Official | Power management abstraction daemon | **Yes** | Battery widget fails |

### 1.5 Wallpaper & Screen Capture
| Package Name | Source | Purpose | Required | What Breaks If Missing |
| :--- | :--- | :--- | :---: | :--- |
| `swaybg` | Official | Wayland wallpaper utility (images & solid colors)| **Yes** | Static wallpapers & canvas colors break |
| `mpvpaper` | AUR | Video wallpaper utility (animated wallpapers) | Optional | Live animated wallpapers fail |
| `ffmpegthumbnailer`| Official | Fast video thumbnail extractor | Optional | Video wallpaper thumbnails in Gallery fallback to ffmpeg |
| `ffmpeg` | Official | Multimedia processing suite | Optional | Video thumbnail fallback |
| `wf-recorder` | Official | Wayland screen recording tool | Optional | Screencasting feature fails |
| `grim` | Official | Wayland screenshot capture utility | **Yes** | Screenshots fail |
| `slurp` | Official | Screen region selector | **Yes** | Region screenshot & screencast fail |
| `wl-clipboard` | Official | Wayland clipboard utilities (`wl-copy`, `wl-paste`)| **Yes** | Clipboard manager & screenshot copying fail |
| `cliphist` | Official | Clipboard history manager | **Yes** | `Mod+V` clipboard history fails |

### 1.6 Typography & Icons
| Package Name | Source | Purpose | Required | What Breaks If Missing |
| :--- | :--- | :--- | :---: | :--- |
| `ttf-inter` | Official | Inter UI font family | **Yes** | System fonts fallback to generic sans-serif |
| `ttf-nerd-fonts-symbols`| Official | Nerd Font icons for Rofi & QML widgets | **Yes** | Icons render as missing glyphs / squares |
| `papirus-icon-theme`| Official | Papirus dark application icons | Optional | Application icons in Fuzzel/Rofi fallback |

---

## 2. Arch Linux One-Line Installation

```bash
# Core Official Packages
sudo pacman -S --needed \
    niri rofi-wayland mako alacritty \
    pipewire wireplumber libpulse playerctl \
    networkmanager bluez bluez-utils \
    brightnessctl power-profiles-daemon lm_sensors upower \
    swaybg ffmpegthumbnailer ffmpeg wf-recorder grim slurp wl-clipboard cliphist \
    ttf-inter ttf-nerd-fonts-symbols papirus-icon-theme python

# AUR Packages (using yay or paru)
yay -S --needed quickshell-git mpvpaper
```
