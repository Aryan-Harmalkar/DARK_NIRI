# 🐚 QuickShell Architecture & Component Breakdown

This document provides a complete technical analysis of the **QuickShell** desktop panel, state management, and all 12 modular QML widgets.

---

## 1. Architectural Overview

[QuickShell](https://github.com/outfoxxed/quickshell) is a native desktop shell engine based on QtQuick and QML. It bridges the Wayland `wlr-layer-shell` protocol directly to Linux CLI tools and D-Bus services.

### Core Window Definition (`quickshell/shell.qml`)
- **Type**: `PanelWindow`
- **Anchor**: Top of screen (`anchors { top: true; left: true; right: true; }`)
- **Height**: 55px (1.25x scaling for high-DPI clarity)
- **Background**: `#E61a1b26` (Tokyo Night dark surface with 90% alpha)
- **Border**: 1px subtle divider (`#292e42`) along the bottom edge
- **Layout Organization**:
  - **Left Section**: Workspaces (`Workspaces.qml`), Distro Badge, Clock (`Clock.qml`), Hardware Monitor (`SysInfo.qml`), Media Player (`Media.qml`).
  - **Center Section**: Dynamic spacing / spacer item.
  - **Right Section**: Screencast Status (`Screencast.qml`), Network (`Network.qml`), Bluetooth (`Bluetooth.qml`), Brightness (`Brightness.qml`), Audio (`Audio.qml`), Mic (`Mic.qml`), Battery (`Battery.qml`), Settings Flyout Trigger (`Settings.qml`).

---

## 2. Component Inventory

### 2.1 `Workspaces.qml` (Workspace Switcher)
- **Polling / Trigger**: Runs `niri msg -j workspaces` via `Process` + `StdioCollector`.
- **Parsing**: Parses JSON array of workspaces, identifying `is_active: true`.
- **Interaction**: Clicking a workspace pill executes `niri msg action focus-workspace <idx>`.

### 2.2 `Clock.qml` (Date & Time Display)
- **Mechanism**: `Timer` firing every 1,000ms.
- **Format**: `Qt.formatDateTime(new Date(), "ddd, MMM d • hh:mm AP")` (e.g. `Fri, Sep 4 • 06:15 PM`).

### 2.3 `SysInfo.qml` (System Metrics Telemetry)
- **Polling**: 2,000ms timer running `quickshell/sysinfo.sh`.
- **Data Ingestion**: Parses pipe-delimited string containing CPU %, Temp, Fan, RAM %, Net Up/Down, AMD iGPU, and NVIDIA dGPU telemetry.
- **Badge & Modal**: Displays compact badge on bar; click opens detailed hardware dashboard.

### 2.4 `Media.qml` (Interactive Media Pill)
- **Polling**: 1,000ms timer running `quickshell/media.sh`.
- **Metadata**: Parses `{{ status }}|||{{ artist }}|||{{ title }}|||{{ album }}|||{{ mpris:artUrl }}`.
- **Interactive Popup**: Hovering / clicking displays album art thumbnail and full playback controls (Previous, Play/Pause, Next).

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
- **Scope**: 2,936 lines of QML orchestrating the control center flyout, quick toggles, sliders, and full modals for Wi-Fi, Bluetooth, Wallpapers, and Notifications.
