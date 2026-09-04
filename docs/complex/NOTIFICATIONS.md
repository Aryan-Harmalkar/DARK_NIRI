# 🔔 Notification Subsystem & Mako

This document covers notification routing, Mako theming, and the interactive notification center.

---

## 1. Mako Daemon Configuration (`mako/config`)

- **Appearance**:
  - Background: `#1a1b26` (Tokyo Night Dark)
  - Text Color: `#a9b1d6`
  - Border: 2px `#7aa2f7` (Tokyo Night Blue) with 10px corner radius
  - Font: `Inter 11`
  - Default Timeout: 5000ms

---

## 2. Notification Center (`notifications.sh` + `Settings.qml`)

- **History Tracking**: Fetches active and recent notifications via `makoctl history -j` and `makoctl list -j`.
- **Dismissal Filtering**: Caches dismissed notification IDs in `/tmp/qs_dismissed.json` to prevent duplicates.
- **Actions**:
  - `dismiss <id>`: Dismisses single notification (`makoctl dismiss -n <id>`).
  - `clear`: Dismisses all notifications (`makoctl dismiss -a`).
  - `count`: Returns integer count of active/unread notifications.
