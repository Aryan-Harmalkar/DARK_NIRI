#!/bin/bash
# Reminder script for Niri / Quickshell
if [ -z "$1" ]; then
    INPUT=$(rofi -dmenu -theme $HOME/DARK_NIRI/rofi/config.rasi -p "Reminder (minutes message)")
    if [ -n "$INPUT" ]; then
        MINS=$(echo "$INPUT" | awk '{print $1}')
        MSG=$(echo "$INPUT" | cut -d' ' -f2-)
        if [[ "$MINS" =~ ^[0-9]+$ ]]; then
            (
                sleep $((MINS * 60))
                notify-send "⏰ Reminder" "$MSG" -i appointment-soon -u critical
            ) &
            notify-send "Reminder Set" "Will alert in $MINS min: $MSG" -i appointment-soon
        else
            notify-send "Reminder" "Invalid format. Example: 10 Take a break" -u low
        fi
    fi
else
    MINS="$1"
    MSG="${2:-Time is up!}"
    (
        sleep $((MINS * 60))
        notify-send "⏰ Reminder" "$MSG" -i appointment-soon -u critical
    ) &
    notify-send "Reminder Set" "Will alert in $MINS min: $MSG" -i appointment-soon
fi
