# 📜 Complete Scripts Reference & Audit

This document audits all 14 shell and Python helper scripts in the repository.

---

## 1. Scripts Catalog

| Script Path | Language | Purpose | Executable |
| :--- | :--- | :--- | :---: |
| `deploy.sh` | Bash | Symlinks repository configs to `~/.config/` with automatic backups | Yes |
| `uninstall.sh` | Bash | Removes symlinks and restores original `.bak` configurations | Yes |
| `niri/startup.sh` | Bash | Bootstraps daemons, syncs D-Bus/systemd environments on Niri start | Yes |
| `niri/osd.sh` | Bash | Dispatches synchronous in-place OSD notifications for volume/brightness | Yes |
| `quickshell/bluetooth.sh` | Python 3 | Bluetooth device discovery, pairing, battery %, and audio profiles | Yes |
| `quickshell/media.sh` | Bash | Queries MPRIS metadata via `playerctl` formatted with `\|\|\|` delimiters | Yes |
| `quickshell/notifications.sh` | Python 3 | Manages Mako notification history, per-item dismissal, and clear-all | Yes |
| `quickshell/powerprofile.sh` | Bash | Cycles and sets power profiles via `powerprofilesctl` or CPU sysfs | Yes |
| `quickshell/reminder.sh` | Bash | Rofi prompt for timed reminders, schedules background `notify-send` | Yes |
| `quickshell/screencast.sh` | Bash | Controller for `wf-recorder` screen recording (start, pause, resume, stop) | Yes |
| `quickshell/shutdown.sh` | Bash | Sudo password wrapper using Rofi for emergency shutdown | Yes |
| `quickshell/sysinfo.sh` | Bash | Hardware sensor gatherer (CPU %, Temp, Fan, RAM, Net delta, GPUs) | Yes |
| `quickshell/wallpaper.sh` | Bash | Wallpaper manager for images, videos (`mpvpaper`), and canvas colors | Yes |
| `quickshell/wifi.sh` | Python 3 | Wi-Fi network manager with dynamic dev detection, password connector, Rofi fallback, and D-Bus WPS monitor | Yes |
