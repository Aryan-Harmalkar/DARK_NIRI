#!/bin/bash
IGNORE="--ignore-player=firefox,firefox.*"
STATUS=$(playerctl $IGNORE status 2>/dev/null)
if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
    playerctl $IGNORE metadata --format "{{ status }}|||{{ artist }}|||{{ title }}|||{{ album }}|||{{ mpris:artUrl }}" 2>/dev/null
else
    echo ""
fi
