# 💻 Developer Guide & Testing Workflow

This document outlines development practices, testing procedures, and contribution guidelines for Dark Niri.

---

## 1. Isolated Component Testing

QuickShell allows testing individual QML widgets without reloading the entire desktop session:

```bash
# Test scratchpad
qs -p quickshell/test.qml

# Test individual component
qs -p quickshell/components/Clock.qml
```

---

## 2. Script & Native Binary Testing

Helper scripts and native Rust utilities can be executed directly from the terminal to verify JSON output and error handling:

```bash
# Test Wi-Fi scanner
quickshell/wifi list

# Test Bluetooth scanner
quickshell/bluetooth list

# Test Notification gatherer
quickshell/notifications list

# Test Theme Manager
quickshell/theme-manager current
quickshell/theme-manager list

# Test Bar Style
quickshell/theme-manager bar-style get

# Test System Monitor metrics
bash quickshell/sysinfo.sh

# Test Media query
bash quickshell/media.sh

# Recompile native Rust tools after modifying dark-tools-rs
cd dark-tools-rs && cargo build --release
```

---

## 3. Style & Contribution Standards

- **Rust (`dark-tools-rs`)**: High-performance, zero-allocation parsing, minimal dependencies, and strict error handling. Emits concise structured JSON for QML ingestion.
- **QML**: Always use `Components.Theme.*` dynamic design tokens (`Theme.qml`) instead of hardcoding hex colors. Keep property bindings reactive.
- **Shell**: Always use `#!/usr/bin/env bash`, quote variable expansions, handle error streams gracefully (`2>/dev/null`), and preserve application states during restarts.
- **Session Edit Logs**: Record all modifications systematically in `Edited/` (`changes/`, `fixes/`, `updates/`, `new-features/`) with timestamped markdown files `YYYY-MM-DD_HH-MM-SS.md`.
- **Git Push Rule**: Never push automatically; always allow the user to review and manually execute `git push`.
