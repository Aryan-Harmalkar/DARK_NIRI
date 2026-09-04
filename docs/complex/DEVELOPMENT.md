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

## 2. Script Testing & Debugging

Helper scripts can be executed directly from the terminal to verify JSON output and error handling:

```bash
# Test Wi-Fi scanner
python3 quickshell/wifi.sh list

# Test Bluetooth scanner
python3 quickshell/bluetooth.sh list

# Test Notification gatherer
python3 quickshell/notifications.sh list

# Test System Monitor metrics
bash quickshell/sysinfo.sh

# Test Media query
bash quickshell/media.sh
```

---

## 3. Style & Contribution Standards

- **QML**: Use declarative property bindings, camelCase property names, and clear separation between UI structure and execution triggers.
- **Shell**: Always use `#!/usr/bin/env bash`, quote variable expansions, and handle error streams gracefully (`2>/dev/null`).
- **Python**: Use standard library modules (`subprocess`, `json`, `sys`, `os`, `re`) to minimize external Python runtime dependencies.
