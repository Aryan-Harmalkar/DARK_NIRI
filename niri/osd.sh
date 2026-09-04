#!/bin/bash

# On-Screen Display (OSD) script for Niri
# Displays volume and brightness changes in the top right using mako/notify-send.
# We use a synchronous hint so the notification smoothly replaces itself.
HINT="string:x-canonical-private-synchronous:sys-osd"

case "$1" in
    vol-up)
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
        VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
        notify-send -h "$HINT" -h int:value:$VOL "Volume" "Volume: ${VOL}%" -i audio-volume-high
        ;;
    vol-down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
        notify-send -h "$HINT" -h int:value:$VOL "Volume" "Volume: ${VOL}%" -i audio-volume-low
        ;;
    vol-mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
            notify-send -h "$HINT" "Volume" "Muted" -i audio-volume-muted
        else
            VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
            notify-send -h "$HINT" -h int:value:$VOL "Volume" "Unmuted (${VOL}%)" -i audio-volume-high
        fi
        ;;
    mic-mute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
            notify-send -h "$HINT" "Microphone" "Muted" -i microphone-sensitivity-muted
        else
            notify-send -h "$HINT" "Microphone" "Unmuted" -i microphone-sensitivity-high
        fi
        ;;
    bri-up)
        brightnessctl set 5%+
        MAX=$(brightnessctl m)
        CUR=$(brightnessctl g)
        PCT=$((CUR * 100 / MAX))
        notify-send -h "$HINT" -h int:value:$PCT "Brightness" "Brightness: ${PCT}%" -i display-brightness
        ;;
    bri-down)
        brightnessctl set 5%-
        MAX=$(brightnessctl m)
        CUR=$(brightnessctl g)
        PCT=$((CUR * 100 / MAX))
        notify-send -h "$HINT" -h int:value:$PCT "Brightness" "Brightness: ${PCT}%" -i display-brightness
        ;;
esac
