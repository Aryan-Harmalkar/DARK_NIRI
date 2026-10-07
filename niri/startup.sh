#!/usr/bin/env bash
# Startup script for Niri - runs silently in the background

# Redirect all stdout and stderr to /dev/null for silent/quiet startup
exec >/dev/null 2>&1

# Disable core dump generation to prevent system freezes and disk thrashing on child process exit
ulimit -c 0

# IMPORTANT: Update D-Bus and Systemd environment to fix apps opening on the wrong TTY/Compositor
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Ensure GTK, GNOME, and Wayland apps render window control buttons (minimize, maximize, close) in headerbars
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true
gsettings set org.cinnamon.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true

# Kill any existing instances to avoid duplicates during config reloads
killall mako 2>/dev/null
killall qs 2>/dev/null

# Restore previous system theme (syncs configs silently without changing user wallpaper)
$HOME/DARK_NIRI/quickshell/theme-manager restore &

# Restore previous power profile mode (power-saver, balanced, performance)
$HOME/DARK_NIRI/quickshell/powerprofile.sh restore &

# Start Mako with our custom config
mako -c $HOME/DARK_NIRI/mako/config &

# Start Quickshell top bar detached
qs -d -p $HOME/DARK_NIRI/quickshell/shell.qml &

# Initialize and restore HTML/Web Wallpaper Engine
$HOME/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl init &

# Start Clipboard Manager (cliphist)
wl-paste --watch cliphist store &

# Run cache & scratch hygiene cleanup in background
$HOME/DARK_NIRI/niri/cleanup.sh &

# Spotify ad muter (mutes Spotify stream during ads, auto-retries)
$HOME/DARK_NIRI/niri/mute-spotify-ads.sh &
