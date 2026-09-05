#!/bin/bash
WALL_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_thumbnails"
STATE_FILE="$HOME/.config/niri/current_wallpaper"

mkdir -p "$WALL_DIR"
mkdir -p "$THUMB_DIR"
mkdir -p "$(dirname "$STATE_FILE")"

case "$1" in
    list)
        # Scan both static images and animated video files
        echo "["
        first=1
        find "$WALL_DIR" -maxdepth 2 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.mp4" -o -name "*.webm" -o -name "*.gif" \) | sort | while IFS= read -r file; do
            name=$(basename "$file")
            ext="${name##*.}"
            ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
            
            # Determine type & thumbnail
            if [[ "$ext" =~ ^(mp4|webm|gif|mkv)$ ]]; then
                type="video"
                thumb="$THUMB_DIR/${name}.jpg"
                if [ ! -f "$thumb" ]; then
                    ffmpegthumbnailer -i "$file" -o "$thumb" -s 320 2>/dev/null || ffmpeg -y -ss 00:00:01 -i "$file" -vframes 1 -q:v 3 "$thumb" 2>/dev/null
                fi
                thumb_path="$thumb"
            else
                type="image"
                thumb_path="$file"
            fi

            if [ $first -eq 0 ]; then echo ","; fi
            first=0
            printf '{"name": "%s", "path": "%s", "thumb": "%s", "type": "%s"}' "$name" "$file" "$thumb_path" "$type"
        done
        echo "]"
        ;;
    set)
        WALL="$2"
        if [ -f "$WALL" ]; then
            ext="${WALL##*.}"
            ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

            if [[ "$ext" =~ ^(mp4|webm|gif|mkv)$ ]]; then
                # Live animated video wallpaper — use mpvpaper (QML can't handle video efficiently)
                killall swaybg 2>/dev/null
                killall mpvpaper 2>/dev/null
                if which mpvpaper >/dev/null 2>&1; then
                    mpvpaper -o "no-audio loop pause=no" '*' "$WALL" &
                fi
            else
                # Static image wallpaper — QML WallpaperWindow handles rendering
                # Just kill any leftover swaybg/mpvpaper processes
                killall mpvpaper 2>/dev/null
                killall swaybg 2>/dev/null
            fi
            echo "$WALL" > "$STATE_FILE"
            notify-send "Wallpaper Updated" "$(basename "$WALL")" -i preferences-desktop-wallpaper
        fi
        ;;
    color)
        COLOR="$2"
        if [ -n "$COLOR" ]; then
            killall mpvpaper 2>/dev/null
            killall swaybg 2>/dev/null
            echo "color:$COLOR" > "$STATE_FILE"
            notify-send "Canvas Color Set" "$COLOR" -i preferences-desktop-wallpaper
        fi
        ;;
    get)
        if [ -f "$STATE_FILE" ]; then
            cat "$STATE_FILE"
        else
            find "$WALL_DIR" -type f | head -n 1
        fi
        ;;
    init)
        # Restore saved wallpaper on startup
        CURRENT=$("$0" get)
        if [ -n "$CURRENT" ]; then
            if [[ "$CURRENT" =~ ^color:(.*)$ ]]; then
                # Solid color — QML handles this natively, nothing to launch
                killall mpvpaper 2>/dev/null
                killall swaybg 2>/dev/null
            elif [ -f "$CURRENT" ]; then
                ext="${CURRENT##*.}"
                ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
                if [[ "$ext" =~ ^(mp4|webm|gif|mkv)$ ]]; then
                    # Video wallpaper — mpvpaper fallback
                    killall swaybg 2>/dev/null
                    killall mpvpaper 2>/dev/null
                    if which mpvpaper >/dev/null 2>&1; then
                        mpvpaper -o "no-audio loop pause=no" '*' "$CURRENT" &
                    fi
                else
                    # Static image — QML WallpaperWindow handles it
                    killall mpvpaper 2>/dev/null
                    killall swaybg 2>/dev/null
                fi
            fi
        fi
        ;;
    *)
        echo "Usage: $0 {list|set <path>|color <#hex>|get|init}"
        exit 1
        ;;
esac
