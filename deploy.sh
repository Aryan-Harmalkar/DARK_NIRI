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

# Build and ensure permissions for Rust performance tools
if [ -d "$SOURCE_DIR/dark-tools-rs" ] && command -v cargo >/dev/null 2>&1; then
    if [ ! -f "$SOURCE_DIR/quickshell/net-tracker" ] || [ ! -f "$SOURCE_DIR/quickshell/wifi" ]; then
        echo "🦀 Building Rust performance tools..."
        (cd "$SOURCE_DIR/dark-tools-rs" && cargo build --release && \
         cp target/release/net-tracker "$SOURCE_DIR/quickshell/" && \
         cp target/release/daily-network-logger "$SOURCE_DIR/quickshell/" && \
         cp target/release/wifi "$SOURCE_DIR/quickshell/" && \
         cp target/release/bluetooth "$SOURCE_DIR/quickshell/" && \
         cp target/release/notifications "$SOURCE_DIR/quickshell/" && \
         cp target/release/wp-ipc "$SOURCE_DIR/quickshell/wallpaper-engine/")
    fi
fi
chmod +x "$SOURCE_DIR/quickshell/net-tracker" \
         "$SOURCE_DIR/quickshell/daily-network-logger" \
         "$SOURCE_DIR/quickshell/wifi" \
         "$SOURCE_DIR/quickshell/bluetooth" \
         "$SOURCE_DIR/quickshell/notifications" \
         "$SOURCE_DIR/quickshell/wallpaper-engine/wp-ipc" 2>/dev/null || true

# Ensure compatibility symlinks exist
(cd "$SOURCE_DIR/quickshell" && \
 [ -f wifi ] && ln -sf wifi wifi.sh; \
 [ -f bluetooth ] && ln -sf bluetooth bluetooth.sh; \
 [ -f notifications ] && ln -sf notifications notifications.sh)

# Deploy background network usage tracker systemd service
if command -v systemctl >/dev/null 2>&1; then
    echo "⚙️  Setting up background network usage tracker..."
    SYSTEMD_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_DIR"
    
    cat << 'SVC' > "$SYSTEMD_DIR/qs-net-tracker.service"
[Unit]
Description=Quickshell Data Usage Background Tracker
After=network.target

[Service]
Type=oneshot
ExecStart=%h/DARK_NIRI/quickshell/net-tracker --update
ExecStop=%h/DARK_NIRI/quickshell/net-tracker --update
RemainAfterExit=yes

[Install]
WantedBy=default.target
SVC

    cat << 'TMR' > "$SYSTEMD_DIR/qs-net-tracker.timer"
[Unit]
Description=Quickshell Data Usage Tracker Periodic Timer

[Timer]
OnBootSec=15s
OnUnitActiveSec=1min
AccuracySec=5s

[Install]
WantedBy=timers.target
TMR

    systemctl --user daemon-reload 2>/dev/null
    systemctl --user enable --now qs-net-tracker.timer 2>/dev/null
    systemctl --user enable --now qs-net-tracker.service 2>/dev/null

    # Link wallpaper engine service
    ln -sf "$SOURCE_DIR/quickshell/wallpaper-engine/quickshell-wallpaper.service" "$SYSTEMD_DIR/quickshell-wallpaper.service"
    systemctl --user daemon-reload 2>/dev/null
fi

echo "✨ Deployment complete! You can now start Niri."
