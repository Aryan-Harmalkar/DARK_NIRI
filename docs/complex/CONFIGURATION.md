# 🛠️ Configuration Guide

This document provides step-by-step instructions for configuring common aspects of the desktop environment.

---

## 1. Modifying Keybindings
- **File to Edit**: `niri/config.kdl`
- Locate the `binds { ... }` block.
- Example: Change terminal launcher to `kitty`:
  ```kdl
  Mod+Return { spawn "kitty"; }
  ```

---

## 2. Changing Top Bar Height or Colors
- **File to Edit**: `quickshell/shell.qml`
- To adjust bar height, edit line 18:
  ```qml
  implicitHeight: 55 // Change to desired pixel height
  ```
- To adjust background transparency:
  ```qml
  color: "#E61a1b26" // Change hex alpha prefix
  ```

---

## 3. Adjusting System Monitor Polling Rates
- **File to Edit**: `quickshell/components/SysInfo.qml`
- Locate the `Timer` component:
  ```qml
  Timer {
      interval: 2000 // Polling interval in milliseconds (default: 2s)
      running: true
      repeat: true
      onTriggered: sysProcess.running = true
  }
  ```
