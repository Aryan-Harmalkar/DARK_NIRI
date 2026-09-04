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

uninstall_app "niri"
uninstall_app "fuzzel"
uninstall_app "quickshell"
uninstall_app "mako"

echo "✨ Uninstallation complete. System restored to previous configurations."
