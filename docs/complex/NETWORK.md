# 📶 Network & Wi-Fi Management Subsystem

This document explains the network architecture handled by `quickshell/wifi.sh` and `quickshell/components/Network.qml`.

---

## 1. Network Subsystem Overview

`wifi.sh` is a Python 3 CLI script wrapping `nmcli` and D-Bus calls to provide complete wireless management.

### Actions Supported
- `list`: Scans available Wi-Fi access points, reads signal strength, band (2.4/5GHz), security, active state, and checks D-Bus for WPS flags. Outputs JSON.
- `toggle`: Toggles Wi-Fi radio between enabled and disabled.
- `connect <ssid> [password]`: Connects to network using NetworkManager.
- `wps <ssid>`: Connects using WPS Push Button Configuration (PBC).
- `disconnect`: Disconnects active wireless connection.
- `forget <ssid>`: Deletes saved connection profile.
- `rescan`: Forces an active Wi-Fi scan and returns updated list.

---

## 2. Advanced WPS Detection via D-Bus

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
