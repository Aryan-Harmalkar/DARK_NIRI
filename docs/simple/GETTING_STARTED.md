# 🚀 Getting Started with Dark Niri

This guide will help you install and use Dark Niri in just 3 simple steps.

---

## Step 1: Install Required Software (Arch Linux)

Open your terminal and paste this single command:

```bash
# Install everything needed from official repositories
sudo pacman -S --needed niri rofi-wayland mako alacritty pipewire wireplumber libpulse playerctl networkmanager bluez bluez-utils brightnessctl power-profiles-daemon lm_sensors upower swaybg ffmpegthumbnailer ffmpeg wf-recorder grim slurp wl-clipboard cliphist ttf-inter ttf-nerd-fonts-symbols papirus-icon-theme python git

# Enable Bluetooth and Wi-Fi services
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon

# Install QuickShell top bar & live wallpaper support from AUR (using yay)
yay -S --needed quickshell-git mpvpaper
```

---

## Step 2: Download and Deploy Dotfiles

Paste this command into your terminal:

```bash
# Clone repository
git clone https://github.com/Aryan-Harmalkar/DARK_NIRI.git ~/DARK_NIRI

# Navigate into the folder and run the installer
cd ~/DARK_NIRI
chmod +x deploy.sh uninstall.sh
./deploy.sh
```

> 📦 **Note**: The installer automatically creates a safe backup of your existing configs.

---

## Step 3: Log In to Niri

1. Log out of your current session.
2. At the login screen (GDM, SDDM, or Ly), select **Niri** from the session menu.
3. Type your password and press **Enter**.
4. You will be greeted by the Tokyo Night dark desktop with the custom top bar!

---

## 🎯 First Things to Try

- Press **`Super + Enter`** to open the terminal.
- Press **`Super + Space`** to open the app launcher and search for any app.
- Click the **Gear icon** in the top-right corner to open the Control Center and connect to Wi-Fi.
- Press **`Super + Shift + /`** at any time to see all shortcuts on screen!
