#!/usr/bin/env bash
# Startup script for Niri - runs silently in the background

# Redirect all stdout and stderr to /dev/null for silent/quiet startup
exec >/dev/null 2>&1

# IMPORTANT: Update D-Bus and Systemd environment to fix apps opening on the wrong TTY/Compositor
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Kill any existing instances to avoid duplicates during config reloads
killall mako 2>/dev/null
killall qs 2>/dev/null

# Start Mako with our custom config
mako -c $HOME/DARK_NIRI/mako/config &

# Start Quickshell top bar detached
qs -d -p $HOME/DARK_NIRI/quickshell/shell.qml &

# Initialize and restore HTML/Web Wallpaper Engine
$HOME/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl init &

# Start Clipboard Manager (cliphist)
wl-paste --watch cliphist store &
