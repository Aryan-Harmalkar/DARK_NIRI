# 📁 Complete File & Folder Structure

This document catalogs every directory and file in the repository, explaining its purpose, dependencies, interactions, and safety rules.

---

## 1. Directory Tree

```text
DARK_NIRI/
├── .gitignore                      # Git ignore rules (runtime state files)
├── AGENTS.md                       # Antigravity IDE pairing rules & workflow guidelines
├── deploy.sh                       # Symlink deployment script
├── uninstall.sh                    # Symlink removal & backup restoration script
├── README.md                       # Repository master overview
├── keybindings-docs.md             # Keybinding reference guide
├── Edited/                         # Modification session edit logs
│   ├── changes/                    # Refactors, renames, config tweaks
│   ├── fixes/                      # Bug fixes, crash fixes, error corrections
│   ├── updates/                    # Improvements, version bumps, doc sync
│   └── new-features/               # New functionality, scripts, components
├── docs/                           # Complete technical documentation suite (28 files)
│   ├── complex/                    # In-depth technical references & architecture
│   ├── simple/                     # Beginner-friendly user guides & tutorials
│   └── wallpapers.md               # HTML/Web Wallpaper Engine manual
├── fuzzel/
│   └── fuzzel.ini                  # Fuzzel application launcher configuration
├── mako/
│   └── config                      # Mako notification daemon configuration
├── niri/
│   ├── config.kdl                  # Main Niri compositor configuration
│   ├── theme.kdl                   # Dynamic theme tokens for Niri focus rings/borders
│   ├── osd.sh                      # On-Screen Display (OSD) notification helper
│   ├── startup.sh                  # Niri session startup and autostart script
│   ├── cleanup.sh                  # Cache & scratch hygiene maintenance script
│   └── current_wallpaper           # Active wallpaper path placeholder
├── dark-tools-rs/                  # High-performance native Rust desktop tools & daemons
│   ├── Cargo.toml                  # Rust workspace package configuration
│   └── src/
│       ├── common.rs               # Zero-allocation sysfs and byte formatting utilities
│       └── bin/
│           ├── net_tracker.rs      # Sub-millisecond network usage telemetry binary
│           ├── daily_network_logger.rs # Daily bandwidth consumption & markdown reporter
│           ├── wifi.rs             # High-performance Wi-Fi manager & WPS monitor
│           ├── bluetooth.rs        # Native Bluetooth discovery & profile manager
│           ├── notifications.rs    # Mako notification history & dismissal backend
│           ├── wallpaper_ipc.rs    # UNIX domain socket IPC client & theme scanner
│           ├── wallpaper_engine.rs # Native Rust GTK4 + WebKit6 Layer Shell wallpaper engine
│           └── theme_manager.rs    # 1-Click atomic whole-system theme orchestrator
├── quickshell/
│   ├── net-tracker                 # Native Rust network telemetry binary
│   ├── daily-network-logger        # Native Rust daily bandwidth logger
│   ├── wifi                        # Native Rust Wi-Fi controller binary
│   ├── wifi.sh                     # Symlink to native wifi binary
│   ├── bluetooth                   # Native Rust Bluetooth controller binary
│   ├── bluetooth.sh                # Symlink to native bluetooth binary
│   ├── notifications               # Native Rust notifications controller binary
│   ├── notifications.sh            # Symlink to native notifications binary
│   ├── theme-manager               # Native Rust 1-click theme orchestrator binary
│   ├── theme.json                  # Active theme color tokens and metadata
│   ├── bar_style.json              # Active bar style state (floating, islands, normal, compact)
│   ├── reload-shell.sh             # Safe shell reload preserving MPRIS playback
│   ├── shell.qml                   # Dynamic multi-style status bar panel
│   ├── media.sh                    # MPRIS media metadata extraction script (Bash)
│   ├── powerprofile.sh             # Power profile switcher & cycler (Bash)
│   ├── reminder.sh                 # Rofi-based timed reminder scheduler (Bash)
│   ├── screencast.sh               # Screen recording controller (wf-recorder) (Bash)
│   ├── shutdown.sh                 # Sudo shutdown password helper (Bash)
│   ├── sysinfo.sh                  # Hardware metrics telemetry gatherer (Bash)
│   ├── wallpaper.sh                # Wallpaper compatibility bridge delegator (Bash)
│   ├── components/
│   │   ├── Theme.qml               # Reactive theme singleton with hot-reload color bindings
│   │   ├── qmldir                  # Component registry for Theme singleton
│   │   ├── Audio.qml               # Top bar audio volume & mute indicator
│   │   ├── Battery.qml             # Neo-glass battery pill with charging indicator
│   │   ├── Bluetooth.qml           # Top bar Bluetooth status indicator
│   │   ├── Brightness.qml          # Top bar display brightness indicator
│   │   ├── Clock.qml               # Dual-tone typography date and time pill
│   │   ├── Media.qml               # Dynamic dancing equalizer bars, album art, playback controls
│   │   ├── Mic.qml                 # Top bar microphone mute indicator
│   │   ├── Network.qml             # Top bar Wi-Fi SSID / connection indicator
│   │   ├── Screencast.qml          # Screen recording indicator & controller
│   │   ├── Settings.qml            # Bento control center, theme studio modal, Wi-Fi/BT/Notif modals
│   │   ├── SysInfo.qml             # Live telemetry pill with rich hardware hover modal
│   │   └── Workspaces.qml          # Fluid morphing active capsule indicator
│   └── wallpaper-engine/           # Modular HTML/Web Wallpaper Engine subsystem
│       ├── wallpaper-engine        # Native Rust GTK4 Layer Shell + WebKit6 background engine
│       ├── wallpaperctl            # Engine CLI controller (powered by native wp-ipc)
│       ├── wp-ipc                  # Native Rust IPC client & theme scanner
│       ├── config.json             # Persistent engine & effect configuration
│       ├── quickshell-wallpaper.service # Systemd user service unit
│       └── themes/                 # Self-contained web themes (cyber-city, aurora, etc.)
└── rofi/
    ├── config.rasi                 # Tokyo Night Rofi theme & layout configuration
    └── theme.rasi                  # Dynamically synced theme tokens generated by theme-manager
```

---

## 2. Directory Audit

### `niri/`
- **Purpose**: Houses the Niri window manager configuration, theme snippet, and startup orchestration scripts.
- **Used by**: Niri compositor session.
- **Required**: **Yes**. Without this directory, Niri will start with default unstyled keybinds and no status bar.
- **Can safely be removed**: **No**.

### `quickshell/`
- **Purpose**: Contains the entire desktop bar, widget components, control center, and native Rust helper binaries.
- **Used by**: `qs` (QuickShell executable).
- **Required**: **Yes**. Core component of the desktop UI.
- **Can safely be removed**: **No**.

### `quickshell/components/`
- **Purpose**: Individual modular QML components representing status bar widgets, popups, full-screen modals, and the `Theme.qml` singleton.
- **Used by**: `shell.qml` and `Settings.qml`.
- **Required**: **Yes**.
- **Can safely be removed**: Individual unused widgets can be removed if their references in `shell.qml` are also deleted.

### `Edited/`
- **Purpose**: Tracks timestamped session edit logs across `changes/`, `fixes/`, `updates/`, and `new-features/` according to repository pairing guidelines.
- **Used by**: Developers and Antigravity pairing sessions for change tracking.
- **Required**: **No** (documentation and history).
- **Can safely be removed**: Yes, without impacting runtime behavior.

### `fuzzel/`
- **Purpose**: Configuration for Fuzzel, a lightweight Wayland application launcher.
- **Used by**: Optional / alternative launcher.
- **Required**: **No** (Rofi is the primary launcher bound in `config.kdl`).
- **Can safely be removed**: Yes, if Fuzzel is not needed.

### `mako/`
- **Purpose**: Configuration for the Mako notification daemon (dynamically styled by `theme-manager`).
- **Used by**: `mako` executable started by `niri/startup.sh`.
- **Required**: **Yes** for notification display and OSD.
- **Can safely be removed**: Only if replaced by another notification daemon (e.g. `dunst`, `swaync`).

### `rofi/`
- **Purpose**: Rofi configuration and dynamically generated `theme.rasi` matching active system theme.
- **Used by**: `Mod+Space` launcher, `Mod+V` clipboard manager, `shutdown.sh`, and `reminder.sh`.
- **Required**: **Yes**.
- **Can safely be removed**: No, multiple keybinds and scripts rely on it.
