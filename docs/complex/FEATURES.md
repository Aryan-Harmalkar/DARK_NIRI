# 🌟 Complete Feature Inventory

This document audits all features provided by the **Dark Niri** desktop environment, detailing how each works, its dependencies, and its implementation status.

---

## 1. Feature Status Matrix

| Feature | Subsystem | Files Involved | Key Dependencies | Status | Notes |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **Scrollable Column Tiling** | Compositor | `niri/config.kdl` | `niri` | **Implemented** | Preset widths: 33.3%, 50%, 66.7% |
| **Dynamic Workspaces** | Compositor / Bar | `Workspaces.qml`, `config.kdl` | `niri` | **Implemented** | Interactive pills, switches via `niri msg` |
| **Global Auto-Maximize & Rules**| Compositor | `niri/config.kdl` | `niri` | **Implemented** | `proportion 1.0` auto-maximizes all new windows |
| **Keybinding Overlay** | Compositor | `niri/config.kdl` | `niri` | **Implemented** | `Mod+Shift+/` hotkey overlay |
| **Application Launcher** | Launcher | `rofi/config.rasi`, `config.kdl` | `rofi-wayland` | **Implemented** | Tokyo Night theme, positioned below bar |
| **Fuzzel Launcher Backup** | Launcher | `fuzzel/fuzzel.ini` | `fuzzel` | **Implemented** | Alternative launcher configuration |
| **Clipboard Manager** | Utilities | `niri/config.kdl`, `startup.sh` | `cliphist`, `wl-clipboard`, `rofi` | **Implemented** | `Mod+V` launches search & decode |
| **Area Screenshot** | Utilities | `niri/config.kdl` | `grim`, `slurp`, `wl-clipboard` | **Implemented** | `Print` captures area, copies to clipboard |
| **Fullscreen Screenshot** | Utilities | `niri/config.kdl` | `grim`, `wl-clipboard` | **Implemented** | `Mod+Print` captures entire screen |
| **On-Screen Display (OSD)** | Feedback | `niri/osd.sh`, `niri/config.kdl` | `notify-send`, `mako`, `wpctl` | **Implemented** | In-place synchronous notification updates |
| **Top Status Bar** | Desktop Shell | `shell.qml` | `quickshell` | **Implemented** | 4 Dynamic Styles: Floating Neo-Glass, Split 3-Islands, Classic Edge-to-Edge, Compact |
| **Control Center Flyout** | Desktop Shell | `Settings.qml` | `quickshell` | **Implemented** | Bento box quick toggles, sliders, and session controls |
| **1-Click Theme Studio** | Theming | `theme-manager`, `Theme.qml` | `dark-tools-rs`, `niri`, `rofi`, `mako` | **Implemented** | 1-Click atomic sync across 7 curated theme presets |
| **Hardware Telemetry** | Monitoring | `SysInfo.qml`, `sysinfo.sh`, `net-tracker` | `dark-tools-rs`, `awk`, `free`, `sensors` | **Implemented** | CPU %, Temp, Fan, PPT Power (W), RAM, Net RX/TX, Disk Read/Write (MB/s & Boot), Daily log, GPUs, Uptime, Total Power (W) |
| **MPRIS Media Player** | Media | `Media.qml`, `media.sh` | `playerctl` | **Implemented** | Dynamic dancing equalizer bars, album art, controls |
| **Wi-Fi Manager Modal** | Network | `Settings.qml`, `wifi` | `nmcli`, `dark-tools-rs (Rust)` | **Implemented** | Network list, Password prompt, WPS detect |
| **WPS Auto-Connect** | Network | `wifi` | `nmcli`, `dark-tools-rs (Rust)` | **Implemented** | Native D-Bus AP flag interrogation in Rust |
| **Bluetooth Manager Modal**| Bluetooth | `Settings.qml`, `bluetooth`| `bluetoothctl`, `dark-tools-rs (Rust)` | **Implemented** | Discovery, Pairing, Battery %, A2DP/HFP |
| **HTML/Web Wallpaper Engine** | Appearance | `Settings.qml`, `wallpaper-engine/`| `dark-tools-rs (Rust)`, `webkitgtk-6.0`, `gtk4-layer-shell` | **Implemented** | Interactive HTML/WebGL themes, Videos, Images, Live FX |
| **Desktop Bridge API** | Appearance | `wallpaper-engine` | `webkitgtk-6.0`, `niri`, `playerctl` | **Implemented** | Sandboxed `window.wallpaper` telemetry & event bridge |
| **Interactive Notif Center**| Notifications | `Settings.qml`, `notifications`| `makoctl`, `dark-tools-rs (Rust)` | **Implemented** | List active/history, dismiss item, clear all |
| **Power Profile Cycling** | Power | `Settings.qml`, `powerprofile.sh`| `powerprofilesctl` / sysfs | **Implemented** | Cycles: power-saver → balanced → performance |
| **Screencasting Controller**| Media / Capture | `Screencast.qml`, `screencast.sh`| `wf-recorder`, `slurp` | **Implemented** | Start area recording, pause/resume, stop |
| **Timed Reminders** | Utilities | `reminder.sh` | `rofi`, `notify-send` | **Implemented** | Background timer with critical notification |
| **Sudo Shutdown Modal** | System | `shutdown.sh`, `Settings.qml` | `rofi`, `sudo`, `shutdown` | **Implemented** | Password prompt for emergency shutdown |
| **Safe Shell Reload** | Utilities | `reload-shell.sh`, `Settings.qml` | `quickshell`, `playerctl` | **Implemented** | 1-Click bar restart preserving MPRIS playback |
| **Session Edit Logging** | Documentation | `AGENTS.md`, `Edited/` | `markdown` | **Implemented** | Timestamped audit logs for all modification sessions |
| **Deployment Automator** | Maintenance | `deploy.sh` | `bash`, `ln` | **Implemented** | Symlinks configs and backs up existing |
| **Uninstaller / Rollback** | Maintenance | `uninstall.sh` | `bash` | **Implemented** | Removes symlinks and restores `.bak` files |
