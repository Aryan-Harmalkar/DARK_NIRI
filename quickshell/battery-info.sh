#!/bin/bash
# Ultra-fast battery & power metrics collector for Quickshell
# Designed to execute on-demand (only when hovered) with zero background overhead.

NOW=$(date +%s)
STATE_FILE="/tmp/qs_battery_state"

# 1. AC Online state detection (check ACAD, AC*, Mains, Adapter)
IS_PLUGGED=0
AC_ONLINE_FILE=""
for ac in /sys/class/power_supply/AC*/online /sys/class/power_supply/ACAD/online /sys/class/power_supply/*/online; do
    if [ -f "$ac" ]; then
        VAL=$(cat "$ac" 2>/dev/null)
        if [ "$VAL" = "1" ]; then
            IS_PLUGGED=1
            AC_ONLINE_FILE="$ac"
            break
        fi
    fi
done

# Fallback check via upower if sysfs was inconclusive
if [ "$IS_PLUGGED" -eq 0 ] && command -v upower >/dev/null 2>&1; then
    UP_ON_BAT=$(upower --dump 2>/dev/null | awk '/on-battery:/ {print $2; exit}')
    if [ "$UP_ON_BAT" = "no" ]; then
        IS_PLUGGED=1
    fi
fi

# 2. Battery telemetry from sysfs
BAT_DIR=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)
CAPACITY="0"
STATUS="Unknown"
CYCLES="0"
HEALTH="100"
VOLTAGE="0.0 V"
POWER_DRAW="0.0 W"
THRESHOLD=""
ENERGY_NOW=""
ENERGY_FULL=""

if [ -d "$BAT_DIR" ]; then
    [ -f "$BAT_DIR/capacity" ] && CAPACITY=$(cat "$BAT_DIR/capacity" 2>/dev/null)
    [ -f "$BAT_DIR/status" ] && STATUS=$(cat "$BAT_DIR/status" 2>/dev/null)
    [ -f "$BAT_DIR/cycle_count" ] && CYCLES=$(cat "$BAT_DIR/cycle_count" 2>/dev/null)
    [ -f "$BAT_DIR/charge_control_end_threshold" ] && THRESHOLD=$(cat "$BAT_DIR/charge_control_end_threshold" 2>/dev/null)

    # Health calculation
    CF=0
    CFD=0
    if [ -f "$BAT_DIR/charge_full" ] && [ -f "$BAT_DIR/charge_full_design" ]; then
        CF=$(cat "$BAT_DIR/charge_full" 2>/dev/null)
        CFD=$(cat "$BAT_DIR/charge_full_design" 2>/dev/null)
    elif [ -f "$BAT_DIR/energy_full" ] && [ -f "$BAT_DIR/energy_full_design" ]; then
        CF=$(cat "$BAT_DIR/energy_full" 2>/dev/null)
        CFD=$(cat "$BAT_DIR/energy_full_design" 2>/dev/null)
    fi

    if [ "$CFD" -gt 0 ] 2>/dev/null; then
        HEALTH=$(awk -v cf="$CF" -v cfd="$CFD" 'BEGIN {h = int((cf/cfd)*100 + 0.5); if (h > 100) h = 100; if (h < 0) h = 0; print h}')
    fi

    # Voltage
    if [ -f "$BAT_DIR/voltage_now" ]; then
        VN=$(cat "$BAT_DIR/voltage_now" 2>/dev/null)
        VOLTAGE=$(awk -v v="$VN" 'BEGIN {printf "%.2f V", v/1000000}')
    fi

    # Power draw / Rate
    if [ -f "$BAT_DIR/power_now" ]; then
        PN=$(cat "$BAT_DIR/power_now" 2>/dev/null)
        POWER_DRAW=$(awk -v p="$PN" 'BEGIN {printf "%.1f W", p/1000000}')
    elif [ -f "$BAT_DIR/current_now" ] && [ -f "$BAT_DIR/voltage_now" ]; then
        CN=$(cat "$BAT_DIR/current_now" 2>/dev/null)
        VN=$(cat "$BAT_DIR/voltage_now" 2>/dev/null)
        POWER_DRAW=$(awk -v c="$CN" -v v="$VN" 'BEGIN {printf "%.1f W", (c*v)/1000000000000}')
    fi

    # Energy in Wh if available
    if [ -f "$BAT_DIR/energy_now" ]; then
        EN=$(cat "$BAT_DIR/energy_now" 2>/dev/null)
        ENERGY_NOW=$(awk -v e="$EN" 'BEGIN {printf "%.1f Wh", e/1000000}')
    elif [ -f "$BAT_DIR/charge_now" ] && [ -f "$BAT_DIR/voltage_now" ]; then
        CN=$(cat "$BAT_DIR/charge_now" 2>/dev/null)
        VN=$(cat "$BAT_DIR/voltage_now" 2>/dev/null)
        ENERGY_NOW=$(awk -v c="$CN" -v v="$VN" 'BEGIN {printf "%.1f Wh", (c*v)/1000000000000}')
    fi

    if [ -f "$BAT_DIR/energy_full" ]; then
        EF=$(cat "$BAT_DIR/energy_full" 2>/dev/null)
        ENERGY_FULL=$(awk -v e="$EF" 'BEGIN {printf "%.1f Wh", e/1000000}')
    elif [ -f "$BAT_DIR/charge_full" ] && [ -f "$BAT_DIR/voltage_now" ]; then
        CF=$(cat "$BAT_DIR/charge_full" 2>/dev/null)
        VN=$(cat "$BAT_DIR/voltage_now" 2>/dev/null)
        ENERGY_FULL=$(awk -v c="$CF" -v v="$VN" 'BEGIN {printf "%.1f Wh", (c*v)/1000000000000}')
    fi
fi

# 3. Track plug-in / on-battery state transition timestamp
CURR_STATE="battery"
[ "$IS_PLUGGED" -eq 1 ] && CURR_STATE="plugged"

START_TS=0
if [ -f "$STATE_FILE" ]; then
    PREV_STATE=$(awk -F'=' '/LAST_STATE/ {print $2}' "$STATE_FILE" 2>/dev/null)
    PREV_TS=$(awk -F'=' '/TIMESTAMP/ {print $2}' "$STATE_FILE" 2>/dev/null)

    if [ "$PREV_STATE" = "$CURR_STATE" ] && [ -n "$PREV_TS" ] && [ "$PREV_TS" -gt 0 ] 2>/dev/null; then
        START_TS=$PREV_TS
    else
        START_TS=$NOW
        echo "LAST_STATE=$CURR_STATE" > "$STATE_FILE"
        echo "TIMESTAMP=$START_TS" >> "$STATE_FILE"
    fi
else
    # First run: fallback to UPower AC update time or uptime
    UP_TS=$(upower -i /org/freedesktop/UPower/devices/line_power_ACAD 2>/dev/null | awk -F'[( ]' '/updated:/ {for(i=1;i<=NF;i++) if ($i=="seconds") print $(i-1)}')
    if [ -n "$UP_TS" ] && [ "$UP_TS" -gt 0 ] 2>/dev/null; then
        START_TS=$((NOW - UP_TS))
    else
        BOOT_SECS=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
        START_TS=$((NOW - BOOT_SECS))
    fi
    echo "LAST_STATE=$CURR_STATE" > "$STATE_FILE"
    echo "TIMESTAMP=$START_TS" >> "$STATE_FILE"
fi

ELAPSED=$((NOW - START_TS))
[ "$ELAPSED" -lt 0 ] && ELAPSED=0
H=$((ELAPSED / 3600))
M=$(((ELAPSED % 3600) / 60))

DUR_STR=""
if [ "$H" -gt 0 ]; then
    DUR_STR="${H}h ${M}m"
elif [ "$M" -gt 0 ]; then
    DUR_STR="${M}m"
else
    DUR_STR="just now"
fi

CLOCK_STR=$(date -d "@$START_TS" +"%H:%M" 2>/dev/null || echo "")

TIME_INFO=""
TIME_LABEL=""
if [ "$IS_PLUGGED" -eq 1 ]; then
    TIME_LABEL="Connected Since"
    if [ -n "$CLOCK_STR" ]; then
        TIME_INFO="$CLOCK_STR ($DUR_STR ago)"
    else
        TIME_INFO="$DUR_STR ago"
    fi
else
    TIME_LABEL="On Battery Since"
    if [ -n "$CLOCK_STR" ]; then
        TIME_INFO="$CLOCK_STR ($DUR_STR ago)"
    else
        TIME_INFO="$DUR_STR ago"
    fi
fi

# Clean cycles format
if [ -z "$CYCLES" ] || [ "$CYCLES" = "-1" ] || [ "$CYCLES" = "0" ]; then
    # Try upower if cycle_count was 0 or missing
    UP_CYCLES=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 2>/dev/null | awk '/charge-cycles:/ {print $2}')
    if [ -n "$UP_CYCLES" ] && [ "$UP_CYCLES" != "N/A" ] && [ "$UP_CYCLES" != "-1" ]; then
        CYCLES="$UP_CYCLES"
    else
        [ "$CYCLES" != "0" ] && CYCLES="N/A"
    fi
fi

# Friendly Charging state text
CHARGING_DESC="$STATUS"
if [ "$IS_PLUGGED" -eq 1 ]; then
    if [ "$STATUS" = "Charging" ]; then
        CHARGING_DESC="Charging ($POWER_DRAW)"
    elif [ "$STATUS" = "Full" ]; then
        CHARGING_DESC="Full (Plugged In)"
    elif [ "$STATUS" = "Not charging" ]; then
        if [ -n "$THRESHOLD" ]; then
            CHARGING_DESC="Plugged in (Limit: ${THRESHOLD}%)"
        else
            CHARGING_DESC="Plugged in (Not charging)"
        fi
    fi
else
    if [ "$STATUS" = "Discharging" ]; then
        CHARGING_DESC="Discharging ($POWER_DRAW)"
    else
        CHARGING_DESC="On Battery ($STATUS)"
    fi
fi

# JSON output
cat << JSON
{
  "capacity": $CAPACITY,
  "status": "$STATUS",
  "charging_desc": "$CHARGING_DESC",
  "is_plugged": $([ "$IS_PLUGGED" -eq 1 ] && echo "true" || echo "false"),
  "health": $HEALTH,
  "cycles": "$CYCLES",
  "time_label": "$TIME_LABEL",
  "time_info": "$TIME_INFO",
  "since_clock": "$CLOCK_STR",
  "duration": "$DUR_STR",
  "voltage": "$VOLTAGE",
  "power_draw": "$POWER_DRAW",
  "energy_now": "$ENERGY_NOW",
  "energy_full": "$ENERGY_FULL",
  "threshold": "$THRESHOLD"
}
JSON
