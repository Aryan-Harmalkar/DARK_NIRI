# ⚙️ Background Daemons & Services

This document details all background services and systemd units utilized by Dark Niri.

---

## 1. System & User Services

| Service / Daemon | Scope | Provider | Purpose | Status / Management |
| :--- | :--- | :--- | :--- | :--- |
| `NetworkManager.service` | System | `networkmanager` | Network interface and Wi-Fi daemon | `sudo systemctl enable --now NetworkManager` |
| `bluetooth.service` | System | `bluez` | Bluetooth protocol stack daemon | `sudo systemctl enable --now bluetooth` |
| `power-profiles-daemon.service` | System | `power-profiles-daemon` | Power governor management | `sudo systemctl enable --now power-profiles-daemon` |
| `pipewire.service` | User | `pipewire` | Core multimedia & audio routing | Auto-started via systemd user session |
| `wireplumber.service` | User | `wireplumber` | PipeWire session policy manager | Auto-started via systemd user session |
| `mako` | Session | `mako` | Wayland notification popup daemon | Started by `niri/startup.sh` |
| `qs` (QuickShell) | Session | `quickshell-git` | Desktop status bar & control center | Started by `niri/startup.sh` (`qs -d -p ...`) |
| `cliphist` | Session | `cliphist` | Wayland clipboard history watcher | Started by `niri/startup.sh` (`wl-paste --watch cliphist store`) |
