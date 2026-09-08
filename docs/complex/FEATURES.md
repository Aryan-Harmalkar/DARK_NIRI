# 🌟 Complete Feature Inventory

This document audits all features provided by the **Dark Niri** desktop environment, detailing how each works, its dependencies, and its implementation status.

---

## 1. Feature Status Matrix

| Feature | Subsystem | Files Involved | Key Dependencies | Status | Notes |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **Scrollable Column Tiling** | Compositor | `niri/config.kdl` | `niri` | **Implemented** | Preset widths: 33.3%, 50%, 66.7% |
| **Dynamic Workspaces** | Compositor / Bar | `Workspaces.qml`, `config.kdl` | `niri` | **Implemented** | Interactive pills, switches via `niri msg` |
| **Window Rules** | Compositor | `niri/config.kdl` | `niri` | **Implemented** | Automatic sizing for WezTerm |
| **Keybinding Overlay** | Compositor | `niri/config.kdl` | `niri` | **Implemented** | `Mod+Shift+/` hotkey overlay |
| **Application Launcher** | Launcher | `rofi/config.rasi`, `config.kdl` | `rofi-wayland` | **Implemented** | Tokyo Night theme, positioned below bar |
| **Fuzzel Launcher Backup** | Launcher | `fuzzel/fuzzel.ini` | `fuzzel` | **Implemented** | Alternative launcher configuration |
| **Clipboard Manager** | Utilities | `niri/config.kdl`, `startup.sh` | `cliphist`, `wl-clipboard`, `rofi` | **Implemented** | `Mod+V` launches search & decode |
| **Area Screenshot** | Utilities | `niri/config.kdl` | `grim`, `slurp`, `wl-clipboard` | **Implemented** | `Print` captures area, copies to clipboard |
| **Fullscreen Screenshot** | Utilities | `niri/config.kdl` | `grim`, `wl-clipboard` | **Implemented** | `Mod+Print` captures entire screen |
| **On-Screen Display (OSD)** | Feedback | `niri/osd.sh`, `niri/config.kdl` | `notify-send`, `mako`, `wpctl` | **Implemented** | In-place synchronous notification updates |
| **Top Status Bar** | Desktop Shell | `shell.qml` | `quickshell` | **Implemented** | 55px height, Tokyo Night dark palette |
| **Control Center Flyout** | Desktop Shell | `Settings.qml` | `quickshell` | **Implemented** | Comprehensive quick toggles & sliders |
| **Hardware Telemetry** | Monitoring | `SysInfo.qml`, `sysinfo.sh` | `bash`, `awk`, `free`, `nvidia-smi` | **Implemented** | CPU %, Temp, Fan, RAM, Net RX/TX, GPUs |
| **MPRIS Media Player** | Media | `Media.qml`, `media.sh` | `playerctl` | **Implemented** | Album art, Play/Pause, Next/Prev, Seek |
| **Wi-Fi Manager Modal** | Network | `Settings.qml`, `wifi.sh` | `nmcli`, `gdbus`, `python3` | **Implemented** | Network list, Password prompt, WPS detect |
| **WPS Auto-Connect** | Network | `wifi.sh` | `nmcli`, `gdbus` | **Implemented** | D-Bus AP flag interrogation |
| **Bluetooth Manager Modal**| Bluetooth | `Settings.qml`, `bluetooth.sh`| `bluetoothctl`, `pactl`, `python3` | **Implemented** | Discovery, Pairing, Battery %, A2DP/HFP |
| **HTML/Web Wallpaper Engine** | Appearance | `Settings.qml`, `wallpaper-engine/`| `webkitgtk-6.0`, `gtk4-layer-shell`, `python3` | **Implemented** | Interactive HTML/WebGL themes, Videos, Images, Canvas colors, Live FX Customizer |
| **Desktop Bridge API** | Appearance | `wallpaper-engine/engine.py` | `webkitgtk-6.0`, `niri`, `playerctl` | **Implemented** | Sandboxed `window.wallpaper` telemetry & event bridge |
| **Interactive Notif Center**| Notifications | `Settings.qml`, `notifications.sh`| `makoctl`, `python3` | **Implemented** | List active/history, dismiss item, clear all |
| **Power Profile Cycling** | Power | `Settings.qml`, `powerprofile.sh`| `powerprofilesctl` / sysfs | **Implemented** | Cycles: power-saver → balanced → performance |
| **Screencasting Controller**| Media / Capture | `Screencast.qml`, `screencast.sh`| `wf-recorder`, `slurp` | **Implemented** | Start area recording, pause/resume, stop |
| **Timed Reminders** | Utilities | `reminder.sh` | `rofi`, `notify-send` | **Implemented** | Background timer with critical notification |
| **Sudo Shutdown Modal** | System | `shutdown.sh`, `Settings.qml` | `rofi`, `sudo`, `shutdown` | **Implemented** | Password prompt for emergency shutdown |
| **UI Quick Reload** | Utilities | `Settings.qml` | `killall`, `qs` | **Implemented** | One-click instant QuickShell reload |
| **Deployment Automator** | Maintenance | `deploy.sh` | `bash`, `ln` | **Implemented** | Symlinks configs and backs up existing |
| **Uninstaller / Rollback** | Maintenance | `uninstall.sh` | `bash` | **Implemented** | Removes symlinks and restores `.bak` files |
