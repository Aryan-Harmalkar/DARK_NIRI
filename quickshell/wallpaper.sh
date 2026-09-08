#!/usr/bin/env bash
# QuickShell Wallpaper compatibility bridge -> delegates to wallpaper-engine/wallpaperctl
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/wallpaper-engine/wallpaperctl" "$@"
