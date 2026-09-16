#!/bin/bash
# Reload QuickShell without interrupting media playback.
# Saves the current MPRIS playback state before killing qs,
# then restores it after the new instance launches.

IGNORE="--ignore-player=firefox,firefox.*"

# 1. Capture current media playback state
MEDIA_WAS_PLAYING=""
if command -v playerctl >/dev/null 2>&1; then
    STATUS=$(playerctl $IGNORE status 2>/dev/null)
    if [ "$STATUS" = "Playing" ]; then
        MEDIA_WAS_PLAYING="1"
    fi
fi

# 2. Kill and restart QuickShell
killall qs 2>/dev/null
sleep 0.1
qs -d -p "$HOME/DARK_NIRI/quickshell/shell.qml" &

# 3. Wait briefly for the new shell to initialize
sleep 0.5

# 4. Restore media playback if it was playing before
if [ "$MEDIA_WAS_PLAYING" = "1" ]; then
    # Check if media is now paused (was interrupted by the reload)
    NEW_STATUS=$(playerctl $IGNORE status 2>/dev/null)
    if [ "$NEW_STATUS" = "Paused" ]; then
        playerctl $IGNORE play 2>/dev/null
    fi
fi

notify-send "Niri" "Bar & Environment Reloaded" -i view-refresh
