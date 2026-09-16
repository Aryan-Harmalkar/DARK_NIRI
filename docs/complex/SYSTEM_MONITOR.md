# 📊 Hardware Monitoring Subsystem

This document details the telemetry collection pipeline implemented by `quickshell/sysinfo.sh` and rendered in `quickshell/components/SysInfo.qml`.

---

## 1. Metrics Pipeline Architecture

```text
/proc/stat, /proc/meminfo, /proc/uptime, /sys/class/hwmon, /sys/class/power_supply, nvidia-smi
                         │
                         ▼
             quickshell/sysinfo.sh (Bash)
                         │
                         ▼ (Structured JSON Object)
    {
      "cpu_name": "AMD Ryzen 7 7445HS", "cpu_cores": "12 Cores",
      "cpu_pct": 12, "cpu_temp": 45, "cpu_fan": "1800 RPM", "cpu_power": "14.2 W",
      "ram_used": "4.2", "ram_total": "15.4", "ram_pct": 27,
      "net_down": "1.2 MB/s", "net_up": "84 KB/s",
      "data_day": "4.2 GB", "data_month": "68.4 GB",
      "amd_name": "AMD Radeon 740M", "amd_temp": 44, "amd_power": "14.2 W", "amd_fan": "Auto",
      "nv_name": "NVIDIA RTX 3050", "nv_temp": 0, "nv_util": 0, "nv_power": "0 W", "nv_status": "Sleeping",
      "uptime": "2d 4h 12m", "total_power": "18.4 W"
    }
                         │
                         ▼ (JSON.parse)
         quickshell/components/SysInfo.qml (QML)
```

---

## 2. Metric Calculations & Sources

### 2.1 CPU Utilization (`cpu_pct`)
- **Source**: `/proc/stat` snapshot comparison.
- **Delta Tracking**: Caches `timestamp`, `total_jiffies`, and `idle_jiffies` in `/tmp/qs_sysinfo_state`.
- **Formula**: `cpu_pct = ((total_delta - idle_delta) / total_delta) * 100`.

### 2.2 CPU Temperature & Fan Speed (`cpu_temp`, `cpu_fan`)
- **Temperature**: Evaluates `sensors` output for `Tctl:` or scans `/sys/class/thermal/thermal_zone*/temp`.
- **Fan RPM**: Evaluates `sensors` output for `cpu_fan:` / `gpu_fan:` RPM values, falling back to "Auto".

### 2.3 CPU Package Power Tracking (`cpu_power`)
- **Mechanism**: Extracts the AMD APU Package Power Tracking (`PPT`) metric from `sensors` under `amdgpu-pci-0500`.
- **Output**: Real-time wattage (e.g. `14.2 W`).

### 2.4 Memory Telemetry (`ram_used`, `ram_total`, `ram_pct`)
- **Source**: `/proc/meminfo` (`MemTotal` and `MemAvailable`).
- **Calculation**: Computes used memory as `MemTotal - MemAvailable`, formatting to GiB with 1-decimal precision and computing integer usage percentage.

### 2.5 Real-Time Total System Power Draw (`total_power`)
- **On Battery (Discharging)**: Reads `/sys/class/power_supply/BAT1/voltage_now` ($\mu V$) and `current_now` ($\mu A$). Calculates true end-to-end device power consumption:
  $$\text{Total Power (W)} = \frac{V \times I}{10^{12}}$$
  This accurately accounts for the screen, motherboard, fans, CPU, RAM, NVMe SSD, and Wi-Fi radio.
- **On AC Power**: Because battery current is zero while on AC, calculates the combined draw of the APU PPT + active NVIDIA dGPU power draw.

### 2.6 System Uptime (`uptime`)
- **Source**: `/proc/uptime`.
- **Formatting**: Converts total uptime seconds into human-readable notation (`Xd Xh Xm` or `Xh Xm`).

### 2.7 Physical Network Bandwidth Delta (`net_down`, `net_up`)
- **Mechanism**: Scans physical network interfaces under `/sys/class/net/*` (filtering out loopback, Docker, virtual, and VPN bridges) and reads `statistics/rx_bytes` and `tx_bytes`.
- **Delta Tracking**: Uses nanosecond timestamps in `/tmp/qs_sysinfo_state` to calculate instantaneous byte rate per second, auto-formatted into `B/s`, `KB/s`, or `MB/s`.

### 2.8 Persistent Daily & Monthly Data Tracking (`data_day`, `data_month`)
- **Mechanism**: Native compiled Rust binary (`dark-tools-rs/net-tracker`) with sub-millisecond execution (~1.3ms, < 2MB RAM). Tracks persistent network consumption across reboots using `/proc/sys/kernel/random/boot_id` and interface statistics.
- **Background Daemon**: Systemd user service `qs-net-tracker.service` and timer `qs-net-tracker.timer`.
- **Daily Markdown Logger**: Synchronously triggers `daily-network-logger` to record detailed daily bandwidth tables in `~/Data Consumption/YYYY-MM.md`.

### 2.9 NVIDIA Dedicated GPU Zero-Wake Telemetry (`nv_*`)
- **Zero-Wake PCI Verification**: To avoid waking the NVIDIA dGPU from low-power runtime suspension (`D3cold`), `sysinfo.sh` scans `/sys/bus/pci/devices/*` for vendor `0x10de` and checks `/sys/bus/pci/devices/*/power/runtime_status`.
- **Suspended State**: If `runtime_status != active`, the script immediately emits `nv_status: "Sleeping"` with `0 W` and `0°C` without invoking `nvidia-smi`.
- **Active State**: Only when the dGPU is active does it query `nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw --format=csv,noheader,nounits`.

### 2.10 Primary NVMe SSD Storage I/O (`disk_*`)
- **Zero SSD Wear Architecture**: Reads `/proc/diskstats` for the primary root disk (`nvme0n1`). Because `/proc` is a kernel procfs pseudo-filesystem residing 100% in RAM, reading these counters involves **zero physical SSD read operations**.
- **RAM-Backed Delta State**: Delta byte comparisons are stored in `/tmp/qs_sysinfo_state` on a `tmpfs` RAM mount, ensuring **zero physical SSD write operations**.
- **Live Throughput**: Measures instantaneous disk read speed (`disk_read`, e.g. `31 KB/s`) and write speed (`disk_write`, e.g. `69 KB/s`).
- **Cumulative Boot I/O**: Calculates total data read (`disk_total_read`, e.g. `2.4 GB`) and written (`disk_total_write`, e.g. `511 MB`) since boot to help users monitor session write loads.

