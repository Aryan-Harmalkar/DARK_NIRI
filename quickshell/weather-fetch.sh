#!/bin/bash
# Optional weather data fetcher for the interactive wallpaper system
# Fetches current weather from OpenWeatherMap and caches to ~/.cache/weather.json
# Called periodically by WallpaperWindow.qml (every 15 minutes)
# Requires: WEATHER_API_KEY and WEATHER_CITY in ~/.config/niri/wallpaper.conf

CONF_FILE="$HOME/.config/niri/wallpaper.conf"
CACHE_FILE="$HOME/.cache/weather.json"

# Read config
if [ ! -f "$CONF_FILE" ]; then
    # No config file — write defaults and exit
    echo '{"weather": "Clear", "temp": 0, "error": "no config"}' > "$CACHE_FILE"
    exit 0
fi

source "$CONF_FILE" 2>/dev/null

if [ -z "$WEATHER_API_KEY" ] || [ -z "$WEATHER_CITY" ]; then
    echo '{"weather": "Clear", "temp": 0, "error": "missing key or city"}' > "$CACHE_FILE"
    exit 0
fi

# Fetch from OpenWeatherMap
RESPONSE=$(curl -sf --max-time 10 \
    "https://api.openweathermap.org/data/2.5/weather?q=${WEATHER_CITY}&appid=${WEATHER_API_KEY}&units=metric" 2>/dev/null)

if [ -n "$RESPONSE" ]; then
    WEATHER_MAIN=$(echo "$RESPONSE" | jq -r '.weather[0].main // "Clear"')
    TEMP=$(echo "$RESPONSE" | jq -r '.main.temp // 0')
    DESCRIPTION=$(echo "$RESPONSE" | jq -r '.weather[0].description // ""')

    printf '{"weather": "%s", "temp": %s, "description": "%s", "fetched": "%s"}\n' \
        "$WEATHER_MAIN" "$TEMP" "$DESCRIPTION" "$(date -Iseconds)" > "$CACHE_FILE"
else
    # Keep stale cache if fetch fails — don't overwrite
    if [ ! -f "$CACHE_FILE" ]; then
        echo '{"weather": "Clear", "temp": 0, "error": "fetch failed"}' > "$CACHE_FILE"
    fi
fi
