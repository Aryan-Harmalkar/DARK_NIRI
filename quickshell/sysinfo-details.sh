#!/bin/bash
# High-speed telemetry details generator for Quickshell
# Runs ONLY on-demand when user hovers a specific section

SECTION="${1:-cpu}"

case "$SECTION" in
  cpu)
    FREQ=$(grep 'cpu MHz' /proc/cpuinfo 2>/dev/null | awk '{sum+=$4; count++} END {if (count>0) printf "%.0f MHz", sum/count; else print "N/A"}')
    GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "powersave")
    LOAD=$(awk '{printf "%.2f, %.2f, %.2f", $1, $2, $3}' /proc/loadavg 2>/dev/null)
    
    PROCS=$(ps -eo pid:8,comm:25,%cpu:8,%mem:8 --sort=-%cpu | head -n 6 | awk 'NR>1 {
        count++;
        pid=$1; cpu=$(NF-1); mem=$NF; comm="";
        for (i=2; i<=NF-2; i++) comm=(comm=="" ? $i : comm " " $i);
        gsub(/"/, "\\\"", comm);
        if (count>1) printf ",";
        printf "{\"pid\": %d, \"name\": \"%s\", \"value\": \"%.1f%%\", \"sub\": \"%.1f%% RAM\", \"pct\": %.1f}", pid, comm, cpu, mem, (cpu > 100 ? 100 : cpu);
    }')
    
    printf '{"section": "cpu", "title": "PROCESSOR DEEP INSPECT", "subtitle": "Top CPU Consumers & Cores", "freq": "%s", "gov": "%s", "load": "%s", "items": [%s]}\n' \
        "$FREQ" "$GOV" "$LOAD" "$PROCS"
    ;;

  ram)
    SWAP=$(free -m 2>/dev/null | awk '/Swap:/ {if ($2>0) printf "%d/%d MB (%.0f%%)", $3, $2, ($3/$2)*100; else print "No Swap"}')
    CACHE=$(free -m 2>/dev/null | awk '/Mem:/ {printf "%d MB", $6}')
    AVAIL=$(free -m 2>/dev/null | awk '/Mem:/ {printf "%.1f GB", $7/1024}')
    
    PROCS=$(ps -eo pid:8,comm:25,rss:12,%mem:8 --sort=-rss | head -n 6 | awk 'NR>1 {
        count++;
        pid=$1; rss_kb=$(NF-1); mem=$NF; comm="";
        for (i=2; i<=NF-2; i++) comm=(comm=="" ? $i : comm " " $i);
        gsub(/"/, "\\\"", comm);
        rss_mb = rss_kb / 1024;
        if (rss_mb >= 1024) rss_str = sprintf("%.1f GB", rss_mb / 1024);
        else rss_str = sprintf("%.0f MB", rss_mb);
        if (count>1) printf ",";
        printf "{\"pid\": %d, \"name\": \"%s\", \"value\": \"%s\", \"sub\": \"%.1f%% RAM\", \"pct\": %.1f}", pid, comm, rss_str, mem, (mem > 100 ? 100 : mem);
    }')
    
    printf '{"section": "ram", "title": "MEMORY DEEP INSPECT", "subtitle": "Top RAM Tasks & Memory Pools", "swap": "%s", "cache": "%s", "avail": "%s", "items": [%s]}\n' \
        "$SWAP" "$CACHE" "$AVAIL" "$PROCS"
    ;;

  disk)
    PARTS=$(df -h -x tmpfs -x devtmpfs -x efivarfs -x overlay 2>/dev/null | awk 'NR>1 && NR<=6 {
        count++;
        gsub(/%/, "", $5);
        if (count>1) printf ",";
        printf "{\"name\": \"%s\", \"mount\": \"%s\", \"used\": \"%s\", \"total\": \"%s\", \"avail\": \"%s\", \"pct\": %d}", $1, $6, $3, $2, $4, int($5);
    }')
    
    ROOT_DEV=$(df / 2>/dev/null | awk 'NR==2 {print $1}')
    ROOT_DISK=$(basename "$ROOT_DEV")
    
    printf '{"section": "disk", "title": "STORAGE MOUNTS & I/O", "subtitle": "Filesystems & Partitions", "root_disk": "%s", "items": [%s]}\n' \
        "$ROOT_DISK" "$PARTS"
    ;;

  net)
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1)
    [ -z "$LOCAL_IP" ] && LOCAL_IP=$(ip -4 -o addr show | awk '!/^[0-9]+: lo/ {print $4}' | cut -d/ -f1 | head -n 1)
    [ -z "$LOCAL_IP" ] && LOCAL_IP="Disconnected"
    
    GATEWAY=$(ip route 2>/dev/null | awk '/default/ {print $3}' | head -n 1)
    [ -z "$GATEWAY" ] && GATEWAY="None"
    
    PRIMARY_DEV=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5}' | head -n 1)
    [ -z "$PRIMARY_DEV" ] && PRIMARY_DEV="wlan0"
    
    CONN_COUNT=$(ss -H -t state established 2>/dev/null | wc -l)
    
    SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -n 1)
    [ -z "$SSID" ] && SSID="Ethernet / Cable"
    
    IFACES=$(ip -o -4 addr show 2>/dev/null | awk '!/^[0-9]+: lo/ {
        count++;
        if (count>1) printf ",";
        printf "{\"name\": \"%s\", \"ip\": \"%s\"}", $2, $4;
    }')
    
    printf '{"section": "net", "title": "NETWORK DEEP INSPECT", "subtitle": "Interfaces & Active Sockets", "ip": "%s", "gateway": "%s", "dev": "%s", "ssid": "%s", "conns": %d, "items": [%s]}\n' \
        "$LOCAL_IP" "$GATEWAY" "$PRIMARY_DEV" "$SSID" "$CONN_COUNT" "$IFACES"
    ;;

  gpu)
    AMD_VRAM_U=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | head -n 1)
    AMD_VRAM_T=$(cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | head -n 1)
    if [ -n "$AMD_VRAM_U" ] && [ -n "$AMD_VRAM_T" ] && [ "$AMD_VRAM_T" -gt 0 ]; then
        AMD_VRAM_U_MB=$((AMD_VRAM_U / 1048576))
        AMD_VRAM_T_MB=$((AMD_VRAM_T / 1048576))
        AMD_VRAM_PCT=$((AMD_VRAM_U * 100 / AMD_VRAM_T))
        AMD_VRAM_FMT="${AMD_VRAM_U_MB} / ${AMD_VRAM_T_MB} MB"
    else
        AMD_VRAM_FMT="Shared RAM"
        AMD_VRAM_PCT=0
    fi
    
    NV_STATE="D3cold (Suspended)"
    NV_PWR="0.0 W"
    NV_VRAM="Off"
    NV_DRV="N/A"
    
    NV_PWR_STATE=$(cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status 2>/dev/null)
    if [ "$NV_PWR_STATE" = "active" ]; then
        NV_STATE="Active"
        NV_RAW=$(nvidia-smi --query-gpu=driver_version,memory.used,memory.total,power.draw --format=csv,noheader,nounits 2>/dev/null | head -n 1)
        if [ -n "$NV_RAW" ]; then
            NV_DRV=$(echo "$NV_RAW" | awk -F',' '{print $1}')
            NV_VRAM=$(echo "$NV_RAW" | awk -F',' '{printf "%s / %s MB", $2, $3}')
            NV_PWR=$(echo "$NV_RAW" | awk -F',' '{printf "%.1f W", $4}')
        fi
    fi
    
    printf '{"section": "gpu", "title": "GRAPHICS ACCELERATORS", "subtitle": "Dual GPU VRAM & Power States", "amd_vram": "%s", "amd_pct": %d, "nv_state": "%s", "nv_vram": "%s", "nv_power": "%s", "nv_drv": "%s"}\n' \
        "$AMD_VRAM_FMT" "$AMD_VRAM_PCT" "$NV_STATE" "$NV_VRAM" "$NV_PWR" "$NV_DRV"
    ;;
esac
