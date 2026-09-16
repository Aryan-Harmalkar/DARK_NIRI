#!/bin/bash
# High-performance hardware & network metrics collector for Quickshell
STATE_FILE="/tmp/qs_sysinfo_state"

# 1. RAM Calculation
MEM_INFO=$(cat /proc/meminfo 2>/dev/null)
MEM_TOTAL_KB=$(echo "$MEM_INFO" | awk '/MemTotal:/ {print $2}')
MEM_AVAIL_KB=$(echo "$MEM_INFO" | awk '/MemAvailable:/ {print $2}')

if [ -n "$MEM_TOTAL_KB" ] && [ -n "$MEM_AVAIL_KB" ]; then
    MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
    RAM_USED_GB=$(awk -v u="$MEM_USED_KB" 'BEGIN {printf "%.1f", u/1048576}')
    RAM_TOTAL_GB=$(awk -v t="$MEM_TOTAL_KB" 'BEGIN {printf "%.1f", t/1048576}')
    RAM_PCT=$(awk -v u="$MEM_USED_KB" -v t="$MEM_TOTAL_KB" 'BEGIN {printf "%.0f", (u/t)*100}')
else
    RAM_USED_GB="0.0"
    RAM_TOTAL_GB="0.0"
    RAM_PCT=0
fi

# 2. CPU Calculation & Model
CPU_MODEL="AMD Ryzen 7 7445HS"
CPU_CORES="12 Cores"
CPU_LINE=$(head -n 1 /proc/stat 2>/dev/null)
CPU_IDLE=$(echo "$CPU_LINE" | awk '{print $5 + $6}')
CPU_TOTAL=$(echo "$CPU_LINE" | awk '{print $2+$3+$4+$5+$6+$7+$8}')

# 3. Physical Network Speed (wlan0, enp2s0, usb0, etc. - excludes virtual/VPN tunnels and Docker bridges)
NET_RX=0
NET_TX=0
for dev_path in /sys/class/net/*; do
    iface=$(basename "$dev_path")
    if [ -e "$dev_path/device" ] || [[ "$iface" =~ ^(wlan|wlp|enp|eth|eno|usb|enx|wwan|wwp) ]]; then
        if [[ ! "$iface" =~ ^(lo|docker|veth|virbr|br-|tun|wg|tailscale|dummy) ]]; then
            rx=$(cat "$dev_path/statistics/rx_bytes" 2>/dev/null || echo 0)
            tx=$(cat "$dev_path/statistics/tx_bytes" 2>/dev/null || echo 0)
            NET_RX=$((NET_RX + rx))
            NET_TX=$((NET_TX + tx))
        fi
    fi
done
[ -z "$NET_RX" ] && NET_RX=0
[ -z "$NET_TX" ] && NET_TX=0
NOW=$(date +%s%N)

CPU_PCT=0
NET_DOWN_FMT="0 B/s"
NET_UP_FMT="0 B/s"

format_speed() {
    local b=$1
    if [ "$b" -ge 1048576 ]; then
        awk -v b="$b" 'BEGIN {printf "%.1f MB/s", b/1048576}'
    elif [ "$b" -ge 1024 ]; then
        awk -v b="$b" 'BEGIN {printf "%.0f KB/s", b/1024}'
    else
        echo "${b} B/s"
    fi
}

format_bytes() {
    local b=$1
    if [ "$b" -ge 1073741824 ]; then
        awk -v b="$b" 'BEGIN {printf "%.1f GB", b/1073741824}'
    elif [ "$b" -ge 1048576 ]; then
        awk -v b="$b" 'BEGIN {printf "%.1f MB", b/1048576}'
    elif [ "$b" -ge 1024 ]; then
        awk -v b="$b" 'BEGIN {printf "%.0f KB", b/1024}'
    else
        echo "${b} B"
    fi
}

# 3a. Primary Disk I/O (100% in-memory /proc/diskstats read - 0 physical SSD wear)
ROOT_DEV=$(df / 2>/dev/null | awk 'NR==2 {print $1}')
ROOT_DISK=$(lsblk -no pkname "$ROOT_DEV" 2>/dev/null)
[ -z "$ROOT_DISK" ] && ROOT_DISK=$(basename "$ROOT_DEV" | sed -E 's/p?[0-9]+$//')
[ -z "$ROOT_DISK" ] && ROOT_DISK="nvme0n1"

DISK_LINE=$(grep -m 1 " $ROOT_DISK " /proc/diskstats 2>/dev/null)
if [ -n "$DISK_LINE" ]; then
    DISK_R_SECTORS=$(echo "$DISK_LINE" | awk '{print $6}')
    DISK_W_SECTORS=$(echo "$DISK_LINE" | awk '{print $10}')
    DISK_R_BYTES=$((DISK_R_SECTORS * 512))
    DISK_W_BYTES=$((DISK_W_SECTORS * 512))
else
    DISK_R_BYTES=0
    DISK_W_BYTES=0
fi

DISK_READ_FMT="0 B/s"
DISK_WRITE_FMT="0 B/s"
DISK_TOT_READ=$(format_bytes "$DISK_R_BYTES")
DISK_TOT_WRITE=$(format_bytes "$DISK_W_BYTES")

if [ -f "$STATE_FILE" ]; then
    PREV_DATA=$(cat "$STATE_FILE" 2>/dev/null)
    P_TIME=$(echo "$PREV_DATA" | awk '{print $1}')
    P_TOTAL=$(echo "$PREV_DATA" | awk '{print $2}')
    P_IDLE=$(echo "$PREV_DATA" | awk '{print $3}')
    P_RX=$(echo "$PREV_DATA" | awk '{print $4}')
    P_TX=$(echo "$PREV_DATA" | awk '{print $5}')
    P_DISK_R=$(echo "$PREV_DATA" | awk '{print $6}')
    P_DISK_W=$(echo "$PREV_DATA" | awk '{print $7}')

    DELTA_TIME=$(awk -v now="$NOW" -v prev="$P_TIME" 'BEGIN {printf "%.3f", (now - prev)/1000000000}')
    if (( $(awk -v dt="$DELTA_TIME" 'BEGIN {print (dt > 0.05)}') )); then
        DIFF_TOTAL=$((CPU_TOTAL - P_TOTAL))
        DIFF_IDLE=$((CPU_IDLE - P_IDLE))
        if [ "$DIFF_TOTAL" -gt 0 ]; then
            CPU_PCT=$(awk -v tot="$DIFF_TOTAL" -v idl="$DIFF_IDLE" 'BEGIN {printf "%.0f", ((tot - idl) / tot) * 100}')
        fi

        DIFF_RX=$((NET_RX - P_RX))
        DIFF_TX=$((NET_TX - P_TX))
        [ "$DIFF_RX" -lt 0 ] && DIFF_RX=0
        [ "$DIFF_TX" -lt 0 ] && DIFF_TX=0

        RX_BPS=$(awk -v rx="$DIFF_RX" -v dt="$DELTA_TIME" 'BEGIN {printf "%.0f", rx / dt}')
        TX_BPS=$(awk -v tx="$DIFF_TX" -v dt="$DELTA_TIME" 'BEGIN {printf "%.0f", tx / dt}')

        NET_DOWN_FMT=$(format_speed "$RX_BPS")
        NET_UP_FMT=$(format_speed "$TX_BPS")

        if [ -n "$P_DISK_R" ] && [ -n "$P_DISK_W" ]; then
            DIFF_DISK_R=$((DISK_R_BYTES - P_DISK_R))
            DIFF_DISK_W=$((DISK_W_BYTES - P_DISK_W))
            [ "$DIFF_DISK_R" -lt 0 ] && DIFF_DISK_R=0
            [ "$DIFF_DISK_W" -lt 0 ] && DIFF_DISK_W=0

            DISK_READ_BPS=$(awk -v r="$DIFF_DISK_R" -v dt="$DELTA_TIME" 'BEGIN {printf "%.0f", r / dt}')
            DISK_WRITE_BPS=$(awk -v w="$DIFF_DISK_W" -v dt="$DELTA_TIME" 'BEGIN {printf "%.0f", w / dt}')

            DISK_READ_FMT=$(format_speed "$DISK_READ_BPS")
            DISK_WRITE_FMT=$(format_speed "$DISK_WRITE_BPS")
        fi
    fi
fi

# Save state
echo "$NOW $CPU_TOTAL $CPU_IDLE $NET_RX $NET_TX $DISK_R_BYTES $DISK_W_BYTES" > "$STATE_FILE"

# 3b. Daily & Monthly Data Usage Tracking (Persistent across boots, physical WAN/LAN/USB tethering only)
if [ -x "$HOME/DARK_NIRI/quickshell/net-tracker" ]; then
    USAGE_OUT=$("$HOME/DARK_NIRI/quickshell/net-tracker" --get 2>/dev/null)
else
    USAGE_OUT=$("$HOME/DARK_NIRI/quickshell/net-tracker.py" --get 2>/dev/null)
fi
DATA_DAY=$(echo "$USAGE_OUT" | awk -F'|' '{print $1}')
DATA_MONTH=$(echo "$USAGE_OUT" | awk -F'|' '{print $2}')
[ -z "$DATA_DAY" ] && DATA_DAY="0 B"
[ -z "$DATA_MONTH" ] && DATA_MONTH="0 B"

# 4. CPU Temperature & Fan Speed
SENSORS_OUT=$(sensors 2>/dev/null)
CPU_TEMP=$(echo "$SENSORS_OUT" | awk '/Tctl:/ {gsub(/[+°C]/, "", $2); print int($2)}' | head -n 1)
[ -z "$CPU_TEMP" ] && CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)}')
[ -z "$CPU_TEMP" ] && CPU_TEMP=40

CPU_FAN=$(echo "$SENSORS_OUT" | awk '/cpu_fan:/ {print $2}' | head -n 1)
[ -z "$CPU_FAN" ] && CPU_FAN="Auto"

GPU_FAN=$(echo "$SENSORS_OUT" | awk '/gpu_fan:/ {print $2}' | head -n 1)
[ -z "$GPU_FAN" ] && GPU_FAN="Auto"

# 5. GPU 1: AMD Radeon 740M (iGPU) + CPU Package Power (PPT)
AMD_TEMP=$(echo "$SENSORS_OUT" | awk '/amdgpu-pci-0500/,/^$/' | awk '/edge:/ {gsub(/[+°C]/, "", $2); print int($2)}' | head -n 1)
[ -z "$AMD_TEMP" ] && AMD_TEMP="$CPU_TEMP"
AMD_POWER_RAW=$(echo "$SENSORS_OUT" | awk '/amdgpu-pci-0500/,/^$/' | awk '/PPT:/ {print $2}' | head -n 1)
[ -z "$AMD_POWER_RAW" ] && AMD_POWER_RAW="0"
AMD_POWER=$(awk -v p="$AMD_POWER_RAW" 'BEGIN {printf "%.1f W", p}')
CPU_POWER="$AMD_POWER"

# 6. GPU 2: NVIDIA GeForce RTX 3050 Laptop (dGPU) - Zero-wake check
NV_STATUS="Sleeping"
NV_TEMP=0
NV_UTIL=0
NV_POWER="0 W"

NV_PCI=$(for pci in /sys/bus/pci/devices/*; do
    if [ -f "$pci/vendor" ] && [ "$(cat "$pci/vendor" 2>/dev/null)" = "0x10de" ] && [ -f "$pci/power/runtime_status" ]; then
        echo "$pci"
        break
    fi
done)

if [ -n "$NV_PCI" ]; then
    NV_PWR_STATE=$(cat "$NV_PCI/power/runtime_status" 2>/dev/null)
else
    NV_PWR_STATE="suspended"
fi

if [ "$NV_PWR_STATE" = "active" ]; then
    NV_INFO=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw --format=csv,noheader,nounits 2>/dev/null | head -n 1)
    if [ -n "$NV_INFO" ]; then
        NV_TEMP=$(echo "$NV_INFO" | awk -F',' '{print int($1)}')
        NV_UTIL=$(echo "$NV_INFO" | awk -F',' '{print int($2)}')
        NV_POWER=$(echo "$NV_INFO" | awk -F',' '{printf "%.1f W", $3}')
        NV_STATUS="Active"
    fi
fi

# 7. Total System Power Draw
# On battery: use voltage * current for real total system power (includes screen, fans, SSD, RAM, everything)
# On AC: battery current is 0, so fall back to APU PPT + dGPU
BAT_STATUS=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)
if [ "$BAT_STATUS" = "Discharging" ]; then
    BAT_V=$(cat /sys/class/power_supply/BAT1/voltage_now 2>/dev/null || echo 0)
    BAT_I=$(cat /sys/class/power_supply/BAT1/current_now 2>/dev/null || echo 0)
    TOTAL_POWER=$(awk -v v="$BAT_V" -v i="$BAT_I" 'BEGIN {printf "%.1f W", (v * i) / 1000000000000}')
else
    NV_POWER_RAW=$(echo "$NV_POWER" | awk '{print $1+0}')
    [ -z "$NV_POWER_RAW" ] && NV_POWER_RAW="0"
    TOTAL_POWER=$(awk -v a="$AMD_POWER_RAW" -v n="$NV_POWER_RAW" 'BEGIN {printf "%.1f W", a + n}')
fi

# 8. System Uptime
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
if [ -n "$UPTIME_SEC" ] && [ "$UPTIME_SEC" -gt 0 ]; then
    UP_DAYS=$((UPTIME_SEC / 86400))
    UP_HOURS=$(((UPTIME_SEC % 86400) / 3600))
    UP_MINS=$(((UPTIME_SEC % 3600) / 60))
    if [ "$UP_DAYS" -gt 0 ]; then
        UPTIME_FMT="${UP_DAYS}d ${UP_HOURS}h ${UP_MINS}m"
    elif [ "$UP_HOURS" -gt 0 ]; then
        UPTIME_FMT="${UP_HOURS}h ${UP_MINS}m"
    else
        UPTIME_FMT="${UP_MINS}m"
    fi
else
    UPTIME_FMT="N/A"
fi

printf '{"cpu_name": "%s", "cpu_cores": "%s", "cpu_pct": %d, "cpu_temp": %d, "cpu_fan": "%s", "cpu_power": "%s", "ram_used": "%s", "ram_total": "%s", "ram_pct": %d, "net_down": "%s", "net_up": "%s", "data_day": "%s", "data_month": "%s", "amd_name": "AMD Radeon 740M", "amd_temp": %d, "amd_power": "%s", "amd_fan": "%s", "nv_name": "NVIDIA RTX 3050", "nv_temp": %d, "nv_util": %d, "nv_power": "%s", "nv_status": "%s", "uptime": "%s", "total_power": "%s", "disk_name": "%s", "disk_read": "%s", "disk_write": "%s", "disk_total_read": "%s", "disk_total_write": "%s"}\n' \
    "$CPU_MODEL" "$CPU_CORES" "$CPU_PCT" "$CPU_TEMP" "$CPU_FAN" "$CPU_POWER" "$RAM_USED_GB" "$RAM_TOTAL_GB" "$RAM_PCT" "$NET_DOWN_FMT" "$NET_UP_FMT" "$DATA_DAY" "$DATA_MONTH" \
    "$AMD_TEMP" "$AMD_POWER" "$GPU_FAN" "$NV_TEMP" "$NV_UTIL" "$NV_POWER" "$NV_STATUS" "$UPTIME_FMT" "$TOTAL_POWER" \
    "$ROOT_DISK" "$DISK_READ_FMT" "$DISK_WRITE_FMT" "$DISK_TOT_READ" "$DISK_TOT_WRITE"
