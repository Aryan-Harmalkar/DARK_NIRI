#!/usr/bin/env bash
ACTION="$1"

if [ "$ACTION" = "sudo" ]; then
    # Prompt password via Rofi with dark theme
    PASS=$(rofi -dmenu -password -p "Sudo Password (Shutdown Now)" -theme $HOME/DARK_NIRI/rofi/config.rasi)
    if [ -n "$PASS" ]; then
        echo "$PASS" | sudo -S shutdown now
    fi
elif [ "$ACTION" = "reboot" ]; then
    systemctl reboot
else
    # Normal shutdown
    systemctl poweroff
fi
