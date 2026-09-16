#!/usr/bin/env bash
# Antigravity & System Cache Hygiene Script
# Runs silently in the background to purge stale scratch files, old diagnostic logs, and crash dumps.
# NEVER removes active project files, user settings, or conversation databases (.db).

# 1. Ensure RAM-backed tmpfs directories exist
mkdir -p /tmp/antigravity-scratch /tmp/rust-target

# 2. Ensure ~/.gemini/antigravity-ide/scratch points to RAM tmpfs
if [ -d "$HOME/.gemini/antigravity-ide" ] && [ ! -L "$HOME/.gemini/antigravity-ide/scratch" ]; then
    rm -rf "$HOME/.gemini/antigravity-ide/scratch" 2>/dev/null
    ln -s /tmp/antigravity-scratch "$HOME/.gemini/antigravity-ide/scratch" 2>/dev/null || true
fi

# 3. Clean stale per-session scratch files older than 3 days
if [ -d "$HOME/.gemini/antigravity-ide/brain" ]; then
    find "$HOME/.gemini/antigravity-ide/brain" -maxdepth 3 -type d -name "scratch" -exec find {} -type f -mtime +3 -delete \; 2>/dev/null
fi

# 4. Clean raw transcript logs older than 7 days (preserves SQLite .db conversation history)
if [ -d "$HOME/.gemini/antigravity-ide/brain" ]; then
    find "$HOME/.gemini/antigravity-ide/brain" -maxdepth 4 -type f -name "*.jsonl" -mtime +7 -delete 2>/dev/null
fi

# 5. Clean IDE diagnostic log directories older than 2 days
if [ -d "$HOME/.config/Antigravity IDE/logs" ]; then
    find "$HOME/.config/Antigravity IDE/logs" -mindepth 1 -maxdepth 1 -type d -mtime +2 -exec rm -rf {} + 2>/dev/null
fi

# 6. Clean stale Crashpad dump files
rm -f "$HOME/.config/Antigravity IDE/Crashpad/pending"/* "$HOME/.config/Antigravity IDE/Crashpad/new"/* 2>/dev/null

# 7. Clean VS Code timeline file history older than 7 days
if [ -d "$HOME/.config/Antigravity IDE/User/History" ]; then
    find "$HOME/.config/Antigravity IDE/User/History" -type f -mtime +7 -delete 2>/dev/null
fi
