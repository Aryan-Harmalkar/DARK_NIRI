# 📶 Network & Wi-Fi Management Subsystem

This document explains the network architecture handled by `quickshell/wifi.sh` and `quickshell/components/Network.qml`.

---

## 1. Network Subsystem Overview

`wifi.sh` is a Python 3 CLI script wrapping `nmcli` and D-Bus calls to provide complete wireless management.

### Actions Supported
- `list`: Scans available Wi-Fi access points, reads signal strength, band (2.4/5GHz), security, active state, and checks D-Bus for WPS flags. Outputs JSON.
- `toggle`: Toggles Wi-Fi radio between enabled and disabled with desktop notifications.
- `connect <ssid> [password]`: Connects to network using NetworkManager with desktop notifications and error reporting.
- `connect-rofi <ssid>`: Prompts for network password via themed Rofi dialog and connects.
- `wps <ssid>`: Connects using WPS Push Button Configuration (PBC) or auto-connects open/saved profiles.
- `disconnect`: Disconnects active wireless connection with dynamic interface detection.
- `forget <ssid>`: Deletes saved connection profile.
- `rescan`: Forces an active Wi-Fi scan and returns updated list.

---

## 2. Wayland Layer-Shell Password Authentication Architecture

In Wayland layer shell (`zwlr_layer_surface_v1`), popups (`xdg_popup`) attached to layer surfaces cannot receive standard keyboard input or grabs. To solve this, `Settings.qml` uses a dedicated overlay `PanelWindow` (`wifiAuthModalWindow`) with:
- `WlrLayershell.layer: WlrLayer.Overlay`
- `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive`
- Full-screen dimmed backdrop with click-to-dismiss and `Keys.onEscapePressed`
- In-place password input with toggle show/hide eye icon, Enter key submission, and auto focus
- Fallback "Rofi Prompt" button option for alternative input

---

## 3. Advanced WPS Detection via D-Bus

`wifi.sh` queries the D-Bus object path of each access point to check for WPS support:
```python
ap_info = subprocess.run([
    'gdbus', 'call', '--system',
    '--dest', 'org.freedesktop.NetworkManager',
    '--object-path', dbus_path,
    '--method', 'org.freedesktop.DBus.Properties.Get',
    'org.freedesktop.NetworkManager.AccessPoint', 'Flags'
], capture_output=True, text=True, timeout=1)
```
- Bit flags `0x2` (WPS), `0x4` (WPS_PBC), or `0x8` (WPS_PIN) indicate active WPS capability.
- When detected, emits a desktop notification informing the user that WPS instant pairing is available.
