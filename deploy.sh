#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config"
# Get the absolute path of the directory this script is in
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Deploying Dark Niri Dotfiles..."

# Ensure ~/.config exists
mkdir -p "$CONFIG_DIR"

deploy_app() {
    local app=$1
    local target="$CONFIG_DIR/$app"
    local source="$SOURCE_DIR/$app"
    
    # Check if the source config folder actually exists in our repository
    if [ ! -d "$source" ] && [ ! -f "$source" ]; then
        echo "⚠️  Source for $app not found in $SOURCE_DIR, skipping..."
        return
    fi
    
    # If a config already exists in ~/.config
    if [ -e "$target" ] || [ -L "$target" ]; then
        # If it's a symlink pointing to our repo already, do nothing
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            echo "✅ $app is already deployed."
            return
        fi
        
        # Otherwise, back it up
        echo "📦 Backing up existing $app config to $target.bak..."
        rm -rf "$target.bak" # Remove old backup if it exists
        mv "$target" "$target.bak"
    fi
    
    # Create the symlink
    echo "🔗 Linking $app..."
    ln -s "$source" "$target"
}

deploy_app "niri"
deploy_app "fuzzel"
deploy_app "quickshell"
deploy_app "mako"

echo "✨ Deployment complete! You can now start Niri."
