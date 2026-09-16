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
- **Polling / Trigger**: Runs `niri msg -j workspaces` via `Process` + `StdioCollector`.
- **Parsing**: Parses JSON array of workspaces, identifying `is_active: true`.
- **Interaction**: Clicking a workspace pill executes `niri msg action focus-workspace <idx>`. Smooth capsule morphing animation on focus shift.

### 2.2 `Clock.qml` (Date & Time Display)
- **Mechanism**: `Timer` firing every 1,000ms.
- **Typography**: Dual-tone typography styling separating weekday, date, and 12-hour time.

### 2.3 `SysInfo.qml` (System Metrics Telemetry)
- **Polling**: 1,000ms timer running `quickshell/sysinfo.sh` while hovering over badge; background 30,000ms timer for network stats.
- **Data Ingestion**: Parses structured JSON object containing CPU %, Temp, Fan, CPU Package Power (PPT in Watts), RAM %, Net Up/Down, persistent daily/monthly usage, NVMe SSD live read/write speeds and boot totals, AMD iGPU, zero-wake NVIDIA dGPU status, system uptime (`Xd Xh Xm`), and real-time total system power draw in Watts.
- **Badge & Modal**: Displays compact telemetry pill on bar; hovering opens detailed 1.75x scaled hardware dashboard card.

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
- **Scope**: Bento box control center providing quick toggles, master volume/brightness sliders, 1-Click Theme Studio (7 presets), 1-Click Bar Style switcher (4 styles), Wi-Fi modal with layer-shell overlay password authentication, Bluetooth modal, and notification center.

---

## 3. Safe Shell Reload (`reload-shell.sh`)

To prevent media interruption during desktop bar restarts, `quickshell/reload-shell.sh` provides an atomic restart routine:
1. Queries `playerctl` for active playback status prior to terminating `qs`.
2. Restarts `qs -d -p shell.qml`.
3. Checks if playback was paused as a side-effect and automatically issues `playerctl play` to resume audio smoothly.
