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

# 3. Total Network (All non-loopback interfaces: wlan0, enp2s0, usb0, etc.)
read -r NET_RX NET_TX < <(awk '$1 !~ /lo:|face/ {rx+=$2; tx+=$10} END {print rx, tx}' /proc/net/dev 2>/dev/null)
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

if [ -f "$STATE_FILE" ]; then
    PREV_DATA=$(cat "$STATE_FILE" 2>/dev/null)
    P_TIME=$(echo "$PREV_DATA" | awk '{print $1}')
    P_TOTAL=$(echo "$PREV_DATA" | awk '{print $2}')
    P_IDLE=$(echo "$PREV_DATA" | awk '{print $3}')
    P_RX=$(echo "$PREV_DATA" | awk '{print $4}')
    P_TX=$(echo "$PREV_DATA" | awk '{print $5}')

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
    fi
fi

# Save state
echo "$NOW $CPU_TOTAL $CPU_IDLE $NET_RX $NET_TX" > "$STATE_FILE"

# 3b. Daily & Monthly Data Usage Tracking (Persistent)
USAGE_OUT=$(python3 -c '
import json, os, time
data_dir = os.path.expanduser("~/.local/share/quickshell")
os.makedirs(data_dir, exist_ok=True)
usage_file = os.path.join(data_dir, "network_usage.json")
cur_date = time.strftime("%Y-%m-%d")
cur_month = time.strftime("%Y-%m")
with open("/proc/sys/kernel/random/boot_id") as f:
    boot_id = f.read().strip()
net_rx, net_tx = 0, 0
with open("/proc/net/dev") as f:
    for line in f:
        if ":" in line and not line.strip().startswith("lo:"):
            parts = line.split(":", 1)[1].split()
            net_rx += int(parts[0])
            net_tx += int(parts[8])
data = {}
if os.path.exists(usage_file):
    try:
        with open(usage_file, "r") as f:
            data = json.load(f)
    except Exception:
        data = {}
saved_boot_id = data.get("boot_id", "")
saved_rx = data.get("last_rx", 0)
saved_tx = data.get("last_tx", 0)
saved_date = data.get("date", cur_date)
saved_month = data.get("month", cur_month)
day_bytes = data.get("day_bytes", 0)
month_bytes = data.get("month_bytes", 0)
if cur_date != saved_date:
    day_bytes = 0
    saved_date = cur_date
if cur_month != saved_month:
    month_bytes = 0
    saved_month = cur_month
if not data:
    day_bytes = net_rx + net_tx
    month_bytes = net_rx + net_tx
elif boot_id != saved_boot_id:
    delta = net_rx + net_tx
    day_bytes += delta
    month_bytes += delta
else:
    delta_rx = max(0, net_rx - saved_rx)
    delta_tx = max(0, net_tx - saved_tx)
    delta = delta_rx + delta_tx
    day_bytes += delta
    month_bytes += delta
data = {
    "boot_id": boot_id,
    "last_rx": net_rx,
    "last_tx": net_tx,
    "date": cur_date,
    "month": cur_month,
    "day_bytes": day_bytes,
    "month_bytes": month_bytes
}
try:
    with open(usage_file + ".tmp", "w") as f:
        json.dump(data, f)
    os.replace(usage_file + ".tmp", usage_file)
except Exception:
    pass
def fmt(b):
    if b >= 1024**3:
        return f"{b / (1024**3):.1f} GB"
    elif b >= 1024**2:
        return f"{b / (1024**2):.1f} MB"
    elif b >= 1024:
        return f"{b / 1024:.0f} KB"
    else:
        return f"{b} B"
print(f"{fmt(day_bytes)}|{fmt(month_bytes)}")
' 2>/dev/null)

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

# 5. GPU 1: AMD Radeon 740M (iGPU)
AMD_TEMP=$(echo "$SENSORS_OUT" | awk '/amdgpu-pci-0500/,/^$/' | awk '/edge:/ {gsub(/[+°C]/, "", $2); print int($2)}' | head -n 1)
[ -z "$AMD_TEMP" ] && AMD_TEMP="$CPU_TEMP"
AMD_POWER=$(echo "$SENSORS_OUT" | awk '/amdgpu-pci-0500/,/^$/' | awk '/PPT:/ {print $2 " " $3}' | head -n 1)
[ -z "$AMD_POWER" ] && AMD_POWER="iGPU"

# 6. GPU 2: NVIDIA GeForce RTX 3050 Laptop (dGPU)
NV_INFO=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw --format=csv,noheader,nounits 2>/dev/null | head -n 1)
if [ -n "$NV_INFO" ]; then
    NV_TEMP=$(echo "$NV_INFO" | awk -F',' '{print int($1)}')
    NV_UTIL=$(echo "$NV_INFO" | awk -F',' '{print int($2)}')
    NV_POWER=$(echo "$NV_INFO" | awk -F',' '{printf "%.1f W", $3}')
    NV_STATUS="Active"
else
    NV_TEMP=0
    NV_UTIL=0
    NV_POWER="0 W"
    NV_STATUS="Sleeping"
fi

printf '{"cpu_name": "%s", "cpu_cores": "%s", "cpu_pct": %d, "cpu_temp": %d, "cpu_fan": "%s", "ram_used": "%s", "ram_total": "%s", "ram_pct": %d, "net_down": "%s", "net_up": "%s", "data_day": "%s", "data_month": "%s", "amd_name": "AMD Radeon 740M", "amd_temp": %d, "amd_power": "%s", "amd_fan": "%s", "nv_name": "NVIDIA RTX 3050", "nv_temp": %d, "nv_util": %d, "nv_power": "%s", "nv_status": "%s"}\n' \
    "$CPU_MODEL" "$CPU_CORES" "$CPU_PCT" "$CPU_TEMP" "$CPU_FAN" "$RAM_USED_GB" "$RAM_TOTAL_GB" "$RAM_PCT" "$NET_DOWN_FMT" "$NET_UP_FMT" "$DATA_DAY" "$DATA_MONTH" \
    "$AMD_TEMP" "$AMD_POWER" "$GPU_FAN" "$NV_TEMP" "$NV_UTIL" "$NV_POWER" "$NV_STATUS"
