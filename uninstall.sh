#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🗑️  Uninstalling Dark Niri Dotfiles..."

uninstall_app() {
    local app=$1
    local target="$CONFIG_DIR/$app"
    local backup="$target.bak"
    
    # Check if target is a symlink pointing to our source dir
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$SOURCE_DIR/$app" ]; then
        echo "❌ Removing symlink for $app..."
        rm "$target"
        
        # Restore backup if it exists
        if [ -e "$backup" ]; then
            echo "♻️  Restoring previous backup for $app..."
            mv "$backup" "$target"
        fi
    else
        echo "⏩ $app does not appear to be linked to Dark Niri, skipping."
    fi
}

# Stop and remove background tracker
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable --now qs-net-tracker.timer 2>/dev/null
    systemctl --user disable --now qs-net-tracker.service 2>/dev/null
    systemctl --user disable --now quickshell-wallpaper.service 2>/dev/null
    rm -f "$HOME/.config/systemd/user/qs-net-tracker.service" "$HOME/.config/systemd/user/qs-net-tracker.timer"
    rm -f "$HOME/.config/systemd/user/quickshell-wallpaper.service"
    systemctl --user daemon-reload 2>/dev/null
fi

uninstall_app "niri"
uninstall_app "fuzzel"
uninstall_app "quickshell"
uninstall_app "mako"

echo "✨ Uninstallation complete. System restored to previous configurations."
