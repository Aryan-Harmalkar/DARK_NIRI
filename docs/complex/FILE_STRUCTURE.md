# 📁 Complete File & Folder Structure

This document catalogs every directory and file in the repository, explaining its purpose, dependencies, interactions, and safety rules.

---

## 1. Directory Tree

```text
DARK_NIRI/
├── .gitignore                      # Git ignore rules (runtime state files)
├── deploy.sh                       # Symlink deployment script
├── uninstall.sh                    # Symlink removal & backup restoration script
├── README.md                       # Repository master overview
├── keybindings-docs.md             # Keybinding reference guide
├── docs/                           # Complete technical documentation suite (28 files)
├── fuzzel/
│   └── fuzzel.ini                  # Fuzzel application launcher configuration
├── mako/
│   └── config                      # Mako notification daemon configuration
├── niri/
│   ├── config.kdl                  # Main Niri compositor configuration
│   ├── osd.sh                      # On-Screen Display (OSD) notification helper
│   ├── startup.sh                  # Niri session startup and autostart script
│   └── current_wallpaper           # Active wallpaper path placeholder
├── dark-tools-rs/                  # High-performance native Rust desktop tools & daemons
│   ├── Cargo.toml                  # Rust workspace package configuration
│   └── src/
│       ├── common.rs               # Zero-allocation sysfs and byte formatting utilities
│       └── bin/
│           ├── net_tracker.rs      # Sub-millisecond network usage telemetry binary
│           └── daily_network_logger.rs # Daily bandwidth consumption & markdown reporter
├── quickshell/
│   ├── net-tracker                 # Compiled native Rust network telemetry binary
│   ├── daily-network-logger        # Compiled native Rust daily bandwidth logger
│   ├── shell.qml                   # Main QuickShell status bar window definition
│   ├── test.qml                    # Development/testing QML scratchpad
│   ├── bluetooth.sh                # Bluetooth discovery & profile backend (Python)
│   ├── media.sh                    # MPRIS media metadata extraction script (Bash)
│   ├── notifications.sh            # Notification history & dismissal backend (Python)
│   ├── powerprofile.sh             # Power profile switcher & cycler (Bash)
│   ├── reminder.sh                 # Rofi-based timed reminder scheduler (Bash)
│   ├── screencast.sh               # Screen recording controller (wf-recorder) (Bash)
│   ├── shutdown.sh                 # Sudo shutdown password helper (Bash)
│   ├── sysinfo.sh                  # Hardware metrics telemetry gatherer (Bash)
│   ├── wallpaper.sh                # Wallpaper compatibility bridge delegator (Bash)
│   ├── wallpaper-engine/           # Modular HTML/Web Wallpaper Engine subsystem
│   │   ├── engine.py               # Core GTK4 Layer Shell + WebKit6 background engine
│   │   ├── wallpaperctl            # Engine CLI controller and IPC client
│   │   ├── config.json             # Persistent engine & effect configuration
│   │   ├── quickshell-wallpaper.service # Systemd user service unit
│   │   └── themes/                 # Self-contained web themes (cyber-city, aurora, etc.)
│   ├── wifi.sh                     # Wi-Fi network manager & WPS monitor (Python)
│   └── components/                 # Reusable QML widgets & control center modules
│       ├── Audio.qml               # Top bar audio volume & mute indicator
│       ├── Battery.qml             # Top bar battery percentage & charging icon
│       ├── Bluetooth.qml           # Top bar Bluetooth status indicator
│       ├── Brightness.qml          # Top bar display brightness indicator
│       ├── Clock.qml               # Top bar live date and time module
│       ├── Media.qml               # Top bar interactive media pill & controls
│       ├── Mic.qml                 # Top bar microphone mute indicator
│       ├── Network.qml             # Top bar Wi-Fi SSID / connection indicator
│       ├── Screencast.qml          # Top bar recording indicator with pause/stop
│       ├── Settings.qml            # Comprehensive Control Center flyout & modals
│       ├── SysInfo.qml             # Top bar hardware monitor badge & modal
│       └── Workspaces.qml          # Top bar dynamic Niri workspace switcher
└── rofi/
    └── config.rasi                 # Tokyo Night Rofi theme & layout configuration
```

---

## 2. Directory Audit

### `niri/`
- **Purpose**: Houses the Niri window manager configuration and startup orchestration scripts.
- **Used by**: Niri compositor session.
- **Required**: **Yes**. Without this directory, Niri will start with default unstyled keybinds and no status bar.
- **Can safely be removed**: **No**.

### `quickshell/`
- **Purpose**: Contains the entire desktop bar, widget components, control center, and backend helper scripts.
- **Used by**: `qs` (QuickShell executable).
- **Required**: **Yes**. Core component of the desktop UI.
- **Can safely be removed**: **No**.

### `quickshell/components/`
- **Purpose**: Individual modular QML components representing status bar widgets, popups, and full-screen modals.
- **Used by**: `shell.qml` and `Settings.qml`.
- **Required**: **Yes**.
- **Can safely be removed**: Individual unused widgets can be removed if their references in `shell.qml` are also deleted.

### `fuzzel/`
- **Purpose**: Configuration for Fuzzel, a lightweight Wayland application launcher.
- **Used by**: Optional / alternative launcher.
- **Required**: **No** (Rofi is the primary launcher bound in `config.kdl`).
- **Can safely be removed**: Yes, if Fuzzel is not needed.

### `mako/`
- **Purpose**: Configuration for the Mako notification daemon (Tokyo Night styling).
- **Used by**: `mako` executable started by `niri/startup.sh`.
- **Required**: **Yes** for notification display and OSD.
- **Can safely be removed**: Only if replaced by another notification daemon (e.g. `dunst`, `swaync`).

### `rofi/`
- **Purpose**: Rofi configuration with custom Tokyo Night theme matching the top bar.
- **Used by**: `Mod+Space` launcher, `Mod+V` clipboard manager, `shutdown.sh`, and `reminder.sh`.
- **Required**: **Yes**.
- **Can safely be removed**: No, multiple keybinds and scripts rely on it.
