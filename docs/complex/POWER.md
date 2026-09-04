# ⚡ Power Management & Battery Subsystem

This document covers power profile switching, battery telemetry, and system power actions.

---

## 1. Power Profiles (`quickshell/powerprofile.sh`)

Cycles the system between three primary power governors:
1. `power-saver`: Minimal CPU clocks, power efficiency priority.
2. `balanced`: Dynamic scaling governor for general productivity.
3. `performance`: Maximum CPU frequency scaling for high workloads.

### Backend Implementation
- **Primary Daemon**: `powerprofilesctl` (communicates with `power-profiles-daemon` over D-Bus).
- **Fallback**: Direct sysfs manipulation of `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`.

---

## 2. Battery Monitoring (`Battery.qml`)

- **Telemetry Source**: Interrogates UPower via D-Bus / `/sys/class/power_supply/BAT*`.
- **Dynamic Icons**: Renders battery level and changes icon when AC adapter is connected / charging.

---

## 3. Power Actions

- **Screen Lock**: `swaylock -f || niri msg action power-off-monitors`
- **Log Out**: `niri msg action quit`
- **Reboot**: `systemctl reboot`
- **Shutdown**: Normal (`systemctl poweroff`) or privileged password prompt (`quickshell/shutdown.sh`).
