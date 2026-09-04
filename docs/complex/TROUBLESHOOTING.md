# 🔍 Troubleshooting Guide & Diagnostics

This document provides diagnosis and remediation steps for common issues.

---

## 1. Diagnostic Matrix

| Symptom | Probable Cause | Verification Check | Fix / Remediation |
| :--- | :--- | :--- | :--- |
| **Top bar does not appear** | `quickshell` not installed or crashed | Run `qs -p quickshell/shell.qml` in terminal | Check for missing QML modules; ensure `quickshell-git` is installed |
| **Notifications not showing** | `mako` daemon not running | Run `pgrep -x mako` | Start mako manually: `mako -c ~/.config/mako/config &` |
| **Audio keys do not work** | `wireplumber` not active | Run `wpctl status` | Ensure `pipewire` and `wireplumber` user services are running |
| **Wi-Fi scan is empty** | NetworkManager inactive | Run `nmcli dev wifi` | Start NetworkManager: `sudo systemctl start NetworkManager` |
| **Bluetooth fails to list** | BlueZ service inactive | Run `bluetoothctl show` | Start bluetooth: `sudo systemctl start bluetooth` |
| **Icons appear as squares** | Missing Nerd Font | Check font installation | Install `ttf-nerd-fonts-symbols` and `ttf-inter` |
| **Wallpaper not loading** | Missing `swaybg` or image | Check `~/.config/niri/current_wallpaper` | Install `swaybg` and select a wallpaper in Gallery |
