# 📜 Complete Scripts & Native Tools Reference

This document audits all shell scripts and native Rust utility binaries in the repository.

---

## 1. Scripts & Binaries Catalog

| Script Path | Language | Purpose | Executable |
| :--- | :--- | :--- | :---: |
| `deploy.sh` | Bash | Symlinks repository configs to `~/.config/` with automatic backups | Yes |
| `uninstall.sh` | Bash | Removes symlinks and restores original `.bak` configurations | Yes |
| `niri/startup.sh` | Bash | Bootstraps daemons, syncs D-Bus/systemd environments on Niri start | Yes |
| `niri/cleanup.sh` | Bash | Cache & scratch hygiene script, purges stale logs/dumps to save SSD writes | Yes |
| `niri/osd.sh` | Bash | Dispatches synchronous in-place OSD notifications for volume/brightness | Yes |
| `quickshell/reload-shell.sh` | Bash | Safe QuickShell restart preserving active MPRIS playback state | Yes |
| `quickshell/theme-manager` | Rust (`dark-tools-rs`) | 1-Click atomic whole-system theme orchestrator & bar style manager | Yes |
| `quickshell/bluetooth` (`bluetooth.sh`) | Rust (`dark-tools-rs`) | Bluetooth device discovery, pairing, battery %, and audio profiles | Yes |
| `quickshell/media.sh` | Bash | Queries MPRIS metadata via `playerctl` formatted with `\|\|\|` delimiters | Yes |
| `quickshell/notifications` (`notifications.sh`) | Rust (`dark-tools-rs`) | Manages Mako notification history, per-item dismissal, and clear-all | Yes |
| `quickshell/powerprofile.sh` | Bash | Cycles and sets power profiles via `powerprofilesctl` or CPU sysfs | Yes |
| `quickshell/reminder.sh` | Bash | Rofi prompt for timed reminders, schedules background `notify-send` | Yes |
| `quickshell/screencast.sh` | Bash | Controller for `wf-recorder` screen recording (start, pause, resume, stop) | Yes |
| `quickshell/shutdown.sh` | Bash | Sudo password wrapper using Rofi for emergency shutdown | Yes |
| `quickshell/sysinfo.sh` | Bash | Hardware sensor gatherer (CPU %, Temp, Fan, PPT Power, RAM, Net, Disk Read/Write, GPUs, Uptime, Total Power) | Yes |
| `quickshell/wallpaper.sh` | Bash | Wallpaper manager for images, videos (`mpvpaper`), and canvas colors | Yes |
| `quickshell/wifi` (`wifi.sh`) | Rust (`dark-tools-rs`) | Wi-Fi network manager with dynamic dev detection, password connector, Rofi fallback, and D-Bus WPS monitor | Yes |
| `quickshell/net-tracker` | Rust (`dark-tools-rs`) | Sub-millisecond persistent network telemetry counter for Quickshell | Yes |
| `quickshell/daily-network-logger` | Rust (`dark-tools-rs`) | Daily bandwidth logger generating monthly markdown reports | Yes |
| `quickshell/wallpaper-engine/wp-ipc` | Rust (`dark-tools-rs`) | Ultra-fast UNIX domain socket IPC client & theme/wallpaper scanner | Yes |
| `quickshell/wallpaper-engine/wallpaper-engine` | Rust (`dark-tools-rs`) | Native GTK4 Layer Shell + WebKit6 interactive background engine | Yes |
