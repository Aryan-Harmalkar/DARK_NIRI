# 🌐 Portability & Multi-User Audit

This document details portability considerations, multi-user readiness, and system-specific assumptions in the codebase.

---

## 1. Portability Audit Findings

### 1.1 Multi-User Readiness ($HOME vs Hardcoded Usernames)
- **Status**: **100% Resolved**.
- All shell scripts use `$HOME`.
- All QML components use `Quickshell.env("HOME")`.
- `niri/config.kdl` wraps spawn actions in `sh -c` to expand `$HOME` at runtime.

### 1.2 Hardcoded Network Interface (`wifi.sh`)
- **Location**: `quickshell/wifi.sh:103` in `disconnect()`:
  ```python
  subprocess.run(['nmcli', 'dev', 'disconnect', 'wlan0'], ...)
  ```
- **Portability Note**: Assumes wireless interface is named `wlan0`. Systems with alternative naming schemes (e.g. `wlp2s0`, `wlan1`) may fail to disconnect via this specific function.
- **Remediation Note**: Best practice is querying active wireless device dynamically via `nmcli -t -f DEVICE,TYPE dev | grep wireless | cut -d: -f1`.

### 1.3 Linux-Specific Dependencies
- Uses `/proc/stat`, `/proc/net/dev`, `/sys/class/hwmon`, and `/sys/class/drm`.
- Requires a Linux kernel and systemd user session.
