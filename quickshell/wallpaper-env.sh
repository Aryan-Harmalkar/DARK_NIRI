#!/bin/bash
# Lightweight environment data provider for the interactive wallpaper system
# Outputs JSON with time, media status, and weather condition.
# Called by WallpaperWindow.qml every few seconds.

HOUR=$(date +%-H)
MINUTE=$(date +%-M)

# Media status from playerctl
IGNORE="--ignore-player=firefox,firefox.*"
MEDIA_STATUS=$(playerctl $IGNORE status 2>/dev/null || echo "Stopped")
# Normalize: Playing, Paused, Stopped
case "$MEDIA_STATUS" in
    Playing|Paused) ;;
    *) MEDIA_STATUS="Stopped" ;;
esac

# Weather condition (cached — updated by weather-fetch.sh)
WEATHER_CACHE="$HOME/.cache/weather.json"
WEATHER=""
WEATHER_TEMP=0
if [ -f "$WEATHER_CACHE" ]; then
    WEATHER=$(jq -r '.weather // "Clear"' "$WEATHER_CACHE" 2>/dev/null)
    WEATHER_TEMP=$(jq -r '.temp // 0' "$WEATHER_CACHE" 2>/dev/null)
fi
[ -z "$WEATHER" ] && WEATHER="Clear"
[ -z "$WEATHER_TEMP" ] && WEATHER_TEMP=0

printf '{"hour": %d, "minute": %d, "media_status": "%s", "weather": "%s", "weather_temp": %s}\n' \
    "$HOUR" "$MINUTE" "$MEDIA_STATUS" "$WEATHER" "$WEATHER_TEMP"
