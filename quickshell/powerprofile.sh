#!/usr/bin/env bash

# Power Profile Manager for Quickshell
# Cycles through: power-saver => balanced => performance => power-saver

ACTION="${1:-get}"
TARGET="$2"

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/niri"
STATE_FILE="$STATE_DIR/power_profile"

get_profile() {
    if command -v powerprofilesctl >/dev/null 2>&1; then
        local prof
        prof=$(powerprofilesctl get 2>/dev/null)
        if [ -n "$prof" ]; then
            echo "$prof"
            return
        fi
    fi
    # Check saved state file if powerprofilesctl didn't return
    if [ -f "$STATE_FILE" ]; then
        local saved
        saved=$(tr -d '[:space:]' < "$STATE_FILE" 2>/dev/null)
        if [ -n "$saved" ]; then
            echo "$saved"
            return
        fi
    fi
    # Fallback to sysfs scaling_governor if powerprofilesctl is unavailable
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        local gov
        gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
        case "$gov" in
            powersave) echo "power-saver" ;;
            performance) echo "performance" ;;
            *) echo "balanced" ;;
        esac
        return
    fi
    echo "balanced"
}

set_profile() {
    local prof="$1"
    local quiet="$2"
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set "$prof" 2>/dev/null
    fi

    # Save state to persistent file
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    echo "$prof" > "$STATE_FILE" 2>/dev/null || true

    if [ "$quiet" != "quiet" ]; then
        case "$prof" in
            power-saver)
                notify-send -u low -i preferences-system-power "Power Profile" "Switched to Power Saving (Eco) mode"
                ;;
            balanced)
                notify-send -u low -i preferences-system-power "Power Profile" "Switched to Balanced mode"
                ;;
            performance)
                notify-send -u low -i preferences-system-power "Power Profile" "Switched to Performance (Turbo) mode"
                ;;
        esac
    fi
    echo "$prof"
}

case "$ACTION" in
    get)
        get_profile
        ;;
    set)
        if [ -n "$TARGET" ]; then
            set_profile "$TARGET"
        else
            get_profile
        fi
        ;;
    cycle)
        CURRENT=$(get_profile)
        case "$CURRENT" in
            power-saver)
                NEXT="balanced"
                ;;
            balanced)
                NEXT="performance"
                ;;
            performance)
                NEXT="power-saver"
                ;;
            *)
                NEXT="balanced"
                ;;
        esac
        set_profile "$NEXT"
        ;;
    restore)
        if [ -f "$STATE_FILE" ]; then
            SAVED=$(tr -d '[:space:]' < "$STATE_FILE" 2>/dev/null)
            if [ -n "$SAVED" ]; then
                set_profile "$SAVED" "quiet"
                exit 0
            fi
        fi
        CURRENT=$(get_profile)
        set_profile "$CURRENT" "quiet"
        ;;
    *)
        get_profile
        ;;
esac
