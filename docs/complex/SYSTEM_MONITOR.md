# 📊 Hardware Monitoring Subsystem

This document details the telemetry collection pipeline implemented by `quickshell/sysinfo.sh` and rendered in `quickshell/components/SysInfo.qml`.

---

## 1. Metrics Pipeline Architecture

```text
/proc/stat, /proc/net/dev, /sys/class/hwmon, nvidia-smi
                         |
                         v
             quickshell/sysinfo.sh (Bash)
                         |
                         v (Pipe-delimited output string)
    CPU_PCT|CPU_TEMP|CPU_FAN|RAM_USED|RAM_TOTAL|RAM_PCT|NET_DOWN|NET_UP|
    AMD_NAME|AMD_TEMP|AMD_POWER|GPU_FAN|NV_TEMP|NV_UTIL|NV_POWER|NV_STATUS
                         |
                         v
        quickshell/components/SysInfo.qml (QML)
```

---

## 2. Metric Calculations & Sources

### 2.1 CPU Utilization (`CPU_PCT`)
- **Method**: Reads `/proc/stat` twice with a 1-second `sleep 1` delta.
- **Formula**: `CPU_PCT = (total_delta - idle_delta) * 100 / total_delta`.

### 2.2 CPU Temperature & Fan Speed (`CPU_TEMP`, `CPU_FAN`)
- **Temperature**: Scans `/sys/class/hwmon/hwmon*/temp*_input` for `k10temp` (AMD) or `coretemp` (Intel). Divides millidegrees Celsius by 1000.
- **Fan RPM**: Scans `/sys/class/hwmon/hwmon*/fan1_input`. Displays RPM value or "Auto".

### 2.3 Memory Telemetry (`RAM_USED`, `RAM_TOTAL`, `RAM_PCT`)
- **Source**: `free -b`.
- **Calculation**: Converts bytes to GiB with 1-decimal precision via `awk`. Calculates integer usage percentage.

### 2.4 Network Bandwidth Delta (`NET_DOWN`, `NET_UP`)
- **Mechanism**: Reads total RX/TX bytes from `/proc/net/dev` across all active physical interfaces (ignoring `lo`).
- **Delta Tracking**: Caches previous timestamp and byte totals in `/tmp/sysinfo_net.tmp`.
- **Formatting**: Divides byte delta by time delta, auto-formatting into `B/s`, `KB/s`, or `MB/s`.


### 2.5 Persistent Daily & Monthly Data Usage Tracking (`DATA_DAY`, `DATA_MONTH`)
- **Mechanism**: `sysinfo.sh` tracks persistent cumulative network consumption across reboots using `/proc/sys/kernel/random/boot_id` and `/proc/net/dev`.
- **Storage Location**: `~/.local/share/quickshell/network_usage.json`.
- **Calculations**:
  - Automatically resets daily metrics at midnight (`%Y-%m-%d`).
  - Automatically resets monthly metrics on the 1st of each month (`%Y-%m`).
  - Handles system reboots by calculating delta from new `boot_id`.
  - Formatted into readable `KB`, `MB`, or `GB` units.

### 2.6 AMD Integrated GPU Telemetry (`AMD_NAME`, `AMD_TEMP`, `AMD_POWER`)
- **Temperature**: Scans `/sys/class/drm/card*/device/hwmon/hwmon*/temp1_input`.
- **Power Draw**: Scans `/sys/class/drm/card*/device/hwmon/hwmon*/power1_average` or displays "iGPU".

### 2.7 NVIDIA Dedicated GPU Telemetry (`NV_TEMP`, `NV_UTIL`, `NV_POWER`, `NV_STATUS`)
- **Query**: Invokes `nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw,pstate --format=csv,noheader,nounits`.
- **Fallback**: If `nvidia-smi` is not present or dGPU is sleeping in hybrid mode, outputs safe default zero values.
