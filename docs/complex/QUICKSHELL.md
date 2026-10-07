# 🐚 QuickShell Architecture & Component Breakdown

This document provides a complete technical analysis of the **QuickShell** desktop panel, state management, and all 12 modular QML widgets.

---

## 1. Architectural Overview

[QuickShell](https://github.com/outfoxxed/quickshell) is a native desktop shell engine based on QtQuick and QML. It bridges the Wayland `wlr-layer-shell` protocol directly to Linux CLI tools and D-Bus services.

## 1. Architectural Overview

[QuickShell](https://github.com/outfoxxed/quickshell) is a native desktop shell engine based on QtQuick and QML. It bridges the Wayland `wlr-layer-shell` protocol directly to Linux CLI tools and D-Bus services.

### Multi-Style Dynamic Status Bar (`quickshell/shell.qml`)
- **Type**: `PanelWindow`
- **Anchor**: Top of screen (`anchors { top: true; left: true; right: true; }`)
- **Reactive Styling**: Driven dynamically by `Components.Theme.barStyle` (`floating`, `islands`, `normal`, `compact`):
  - **Floating**: Neo-glass island dock with rounded corners (`radius: 22`), glass sheen highlight, and glowing borders.
  - **Islands**: Split 3-piece modular capsules for Left, Center, and Right floating over a transparent desktop backdrop.
  - **Normal**: Classic edge-to-edge flush panel with subtle bottom divider line.
  - **Compact**: Ultra-slim minimalist floating profile with low-profile padding.
- **Color Engine**: Centralized reactive tokens via `Components.Theme.*` (singleton defined in `components/Theme.qml`).
- **Layout Organization**:
  - **Left Section**: Workspaces (`Workspaces.qml`), Distro Badge, Clock (`Clock.qml`), Hardware Monitor (`SysInfo.qml`), Media Player (`Media.qml`).
  - **Center Section**: Dynamic spacing / spacer item.
  - **Right Section**: Screencast Status (`Screencast.qml`), Network (`Network.qml`), Bluetooth (`Bluetooth.qml`), Brightness (`Brightness.qml`), Audio (`Audio.qml`), Mic (`Mic.qml`), Battery (`Battery.qml`), Theme Studio Quick Button, Settings Flyout Trigger (`Settings.qml`).

---

## 2. Component Inventory

### 2.1 `Workspaces.qml` (Workspace Switcher)
- **Polling / Trigger**: Real-time event stream via `niri msg -j event-stream` (reacting to `WorkspacesChanged`, `WorkspaceActivated`, `WindowFocusChanged`), backed by one-shot `niri msg -j workspaces` and a 3-second sync timer.
- **Multi-Monitor Filtering**: Automatically filters workspaces to the current screen (`screenName` matching `modelData.name` from `Quickshell.screens`), showing only the active monitor's workspaces per bar.
- **Interaction & Hitbox**: Full 28px height click target with `Qt.PointingHandCursor`. Clicking any workspace pill or dot activates the workspace (`niri msg action focus-workspace <idx>`). Mouse wheel scrolls through workspaces (`focus-workspace-down` / `focus-workspace-up`) with accumulated delta throttling and zero cursor movement, allowing seamless continuous scrolling.
- **Visuals & Animation**: Distinct active capsule morphing animation with `Theme.accent`, hover expansions, occupied workspace dimming (`Theme.fgMuted`), and press feedback animations.

### 2.2 `Clock.qml` (Date & Time Display & Interactive Calendar Popup)
- **Top Bar Pill**: Dual-tone typography styling separating weekday, month, day, and 12-hour time with Tokyo Night accent separation dot.
- **Hover Cockpit Popup Window (576px Bento Layout)**: Activated strictly on hover over the status bar pill, supported by a 350ms grace exit timer.
  - **Left Column (260px Time & Temporal Cockpit)**:
    - **Digital Clock Hero**: Large bold 12-hour time (`HH:mm`), live ticking seconds (`:ss` in accent color), and AM/PM tag.
    - **24-Hour & UTC Clocks**: Secondary display showing military 24-hour time and live UTC/Zulu time for developers.
    - **Full Date & Milestones**: Long-form date string, ISO Week number pill (`Wk 39`), Day of Year progress (`Day 266/365`), and annual Quarter badge (`Q3`).
    - **Temporal Progress Gauges**: Real-time visual progress bars tracking Day Elapsed % and Year Elapsed %.
    - **Timezone, Uptime & NTP Status**: Displays system timezone region (`Asia/Kolkata`), abbreviation and UTC offset (`IST (+05:30)`), system uptime (`Up 25m`), and NTP synchronization status (`NTP Synced`).
  - **Right Column (268px Interactive Calendar Widget)**:
    - **Header Navigation**: Current month/year heading with navigation buttons (`◀` previous month, `▶` next month) and a 1-click `Today` return button.
    - **Day Labels**: Monday through Sunday header row (`Mo` - `Su`) with weekend distinction.
    - **Full 42-Cell Monthly Grid**: High-contrast highlight on today's date (`Theme.accent` pill with bold contrasting text), muted trailing/leading days from adjacent months, and hover effects on all days.
    - **Footer Metrics**: Long date summary and live Unix/Epoch timestamp counter.
- **Helper Script**: Powered by `quickshell/clock-info.sh` for instant sub-millisecond retrieval of system timezone name, abbreviation, UTC offset, system uptime, and NTP synchronization.

### 2.3 `SysInfo.qml` (System Metrics Telemetry & Section Deep Inspector)
- **Polling & Execution Model**: Strict hover-only execution. `sysinfo.sh` and `sysinfo-details.sh` run at 1,000ms intervals **strictly while hovering**. Zero background polling timers, zero background CPU cycles, and 0 bytes of internet data usage (all telemetry is read directly from kernel memory).
- **Cockpit Architecture**: Dual-pane Bento Cockpit layout (940px width):
  - **Left Column (540px Overview)**: CPU Load & Package Wattage, Memory (RAM) breakdown, Network Live Rates & Daily/Monthly bandwidth, NVMe SSD Live Read/Write throughput & cumulative boot I/O, AMD Radeon 740M iGPU, and NVIDIA RTX 3050 zero-wake D3cold status.
  - **Right Column (354px Deep Inspector)**: Dynamic contextual inspector powered by `quickshell/sysinfo-details.sh`. Hovering or clicking any hardware card on the left instantly streams deep diagnostic telemetry:
    - **CPU**: Top 5 processes by `%CPU` (with PID, command, and visual usage bars), core frequencies, scaling governor, and load averages.
    - **RAM**: Top 5 memory-consuming tasks (with PID, RSS in MB/GB, and memory %), swap allocation, cache/buffers, and free memory.
    - **Storage**: Mounted filesystem partitions (`df -h`), volume usage percentages, available free space, and primary device path.
    - **Network**: Active connection details, Wi-Fi SSID, interface IPv4 addresses, default gateway, and active socket connections.
    - **GPU**: AMD iGPU VRAM allocation pool and NVIDIA RTX 3050 PCIe runtime suspend / dedicated VRAM state.
- **Interaction**: 350ms smooth hover grace delay prevents accidental popup dismissals when navigating between the bar badge, cards, and deep inspector list.

### 2.4 `Media.qml` (Interactive Media Pill)
- **Polling**: 1,000ms timer running `quickshell/media.sh`.
- **Visualizer**: 3 dynamic dancing equalizer bars with randomized heights that animate live during track playback.
- **Interactive Popup**: Hovering / clicking displays album art thumbnail, track position seeking, and full playback controls (Previous, Play/Pause, Next).

### 2.5 `Screencast.qml` (Recording Controller)
- **Polling**: Runs `quickshell/screencast.sh status`.
- **Visibility**: Automatically hidden when status is `idle`; reveals red pulsing recording indicator when active.
- **Controls**: Pause/Resume and Stop buttons.

### 2.6 `Network.qml` (Wi-Fi SSID Indicator)
- **Polling**: 5,000ms timer running `nmcli -t -f active,ssid dev wifi`.
- **Status**: Displays connected SSID or "Disconnected".

### 2.7 `Bluetooth.qml` (Bluetooth Status)
- **Polling**: 5,000ms timer checking `bluetoothctl show`.
- **Status**: Renders icon and active connected device name.

### 2.8 `Brightness.qml` (Backlight Indicator)
- **Polling**: 3,000ms timer running `brightnessctl -m`.
- **Output**: Displays percentage string (e.g. `65%`).

### 2.9 `Audio.qml` (Speaker Volume & Mute)
- **Polling**: 2,000ms timer running `wpctl get-volume @DEFAULT_AUDIO_SINK@`.
- **Output**: Shows volume percentage and muted indicator.

### 2.10 `Mic.qml` (Microphone Mute Status)
- **Polling**: 2,000ms timer running `wpctl get-volume @DEFAULT_AUDIO_SOURCE@`.
- **Output**: Visual indicator when microphone is muted.

### 2.11 `Battery.qml` (Power & Battery Level)
- **Polling**: 5,000ms timer interrogating UPower or `/sys/class/power_supply/`.
- **Output**: Battery percentage and dynamic charging/discharging glyph.

### 2.12 `Settings.qml` (Control Center & Modals)
- **Scope**: Bento box control center providing quick toggles, master volume/brightness sliders, 1-Click Theme Studio (7 presets), 1-Click Bar Style switcher (4 styles), Wallpaper Engine control & live FX studio, Wi-Fi modal with layer-shell overlay password authentication, Bluetooth modal, and notification center.
- **State Persistence**: Options selected in QuickShell settings (active theme, bar style, wallpaper engine configuration and toggle state, power profile) persist automatically across user logouts and system restarts via atomic disk state files and startup restoration hooks.

---

## 3. State Persistence & Boot Restoration

To guarantee user state survives logouts, reboots, and shell reloads, QuickShell uses an instant disk-backed reactive state model:

1. **System Theme & Colors (`components/Theme.qml`)**:
   - Uses `Quickshell.Io.FileView` with `preload: true` and `watchChanges: true` to load `quickshell/theme.json` synchronously at QML construction.
   - `theme-manager restore` runs during `niri/startup.sh` to synchronize Niri, Mako, Rofi, Fuzzel, and QuickShell configs from `~/.config/niri/current_theme.json` without overriding user wallpapers or triggering notification popups.
2. **Bar Style Docking (`quickshell/bar_style.json`)**:
   - `Theme.qml` binds directly to `quickshell/bar_style.json` via `FileView`, rendering the selected dock geometry (`floating`, `islands`, `normal`, or `compact`) instantaneously with zero layout flicker.
3. **Power Profile (`quickshell/powerprofile.sh`)**:
   - Writes active profile (`power-saver`, `balanced`, `performance`) to `~/.config/niri/power_profile`.
   - `niri/startup.sh` executes `powerprofile.sh restore &` to quietly re-apply the power profile on boot.
4. **HTML/Web Wallpaper Engine (`quickshell/wallpaper-engine/wallpaperctl`)**:
   - Tracks engine enabled/disabled state in `~/.config/niri/wallpaper_engine_enabled`.
   - When disabled in settings, `wallpaperctl init` avoids starting the background engine process. When enabled, it starts up and loads all saved visual effects, FPS, quality, and active wallpaper targets directly from `config.json`.

---

## 4. Safe Shell Reload (`reload-shell.sh`)

To prevent media interruption during desktop bar restarts, `quickshell/reload-shell.sh` provides an atomic restart routine:
1. Queries `playerctl` for active playback status prior to terminating `qs`.
2. Restarts `qs -d -p shell.qml`.
3. Checks if playback was paused as a side-effect and automatically issues `playerctl play` to resume audio smoothly.
