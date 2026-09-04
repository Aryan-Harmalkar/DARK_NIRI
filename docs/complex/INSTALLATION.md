# 🚀 Complete Installation Guide

This guide walks you through bootstrapping the **Dark Niri** desktop environment from a fresh Arch Linux installation.

---

## 1. Prerequisites & Package Installation

Ensure your system is up to date and install required dependencies:

```bash
# 1. Update system package databases
sudo pacman -Syu

# 2. Install official repository packages
sudo pacman -S --needed     niri rofi-wayland mako alacritty     pipewire wireplumber libpulse playerctl     networkmanager bluez bluez-utils     brightnessctl power-profiles-daemon lm_sensors upower     swaybg ffmpegthumbnailer ffmpeg wf-recorder grim slurp wl-clipboard cliphist     ttf-inter ttf-nerd-fonts-symbols papirus-icon-theme python git

# 3. Enable essential system services
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now power-profiles-daemon

# 4. Install AUR helper (if not already installed) & AUR packages
# (e.g. using yay)
yay -S --needed quickshell-git mpvpaper
```

---

## 2. Deploying Dotfiles

```bash
# 1. Clone repository to your home directory
git clone https://github.com/Aryan-Harmalkar/DARK_NIRI.git ~/DARK_NIRI

# 2. Navigate to directory and execute deployment script
cd ~/DARK_NIRI
chmod +x deploy.sh uninstall.sh
./deploy.sh
```

---

## 3. Starting the Session

Launch Niri from a TTY or select **Niri** in your Display Manager (GDM, SDDM, or Ly):
```bash
niri-session
```
