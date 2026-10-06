#!/usr/bin/env bash
# Toggle Quickshell top bar visibility across all monitors

QS_PATH="$HOME/DARK_NIRI/quickshell/shell.qml"

# 1. Try with explicit path (how DARK_NIRI launches Quickshell)
if qs ipc -p "$QS_PATH" call bar toggle 2>/dev/null; then
    exit 0
fi

# 2. Try default config (~/.config/quickshell)
if qs ipc call bar toggle 2>/dev/null; then
    exit 0
fi

# 3. If Quickshell is not running at all, launch it
qs -d -p "$QS_PATH" &
