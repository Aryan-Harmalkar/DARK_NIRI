# 🖥️ Display & Wallpaper Management Subsystem

This document details display backlight control and the modular HTML/Web Wallpaper Engine.

---

## 1. Backlight Control

- **CLI Tool**: `brightnessctl`
- **Adjustment**: Increments/decrements in 5% steps via `niri/osd.sh bri-up` and `bri-down`.
- **Slider**: Controlled via `brightnessctl set <val>%` in `Settings.qml`.

---

## 2. HTML/Web Wallpaper Engine (`quickshell/wallpaper-engine/`)

The background wallpaper layer is powered by a dedicated hardware-accelerated process built with `gtk4-layer-shell` and `webkitgtk-6.0`, isolated from QuickShell.

Detailed architecture and developer APIs: [`docs/wallpapers.md`](../wallpapers.md).

### 2.1 Supported Modes

1. **Self-Contained Web Themes**:
   - Directory-based HTML/CSS/JS/WebGL themes (`cyber-city`, `aurora`, `cyber-matrix`, `particles`, `waves`, `fallback`).
   - Integrated with the sandboxed `window.wallpaper` bridge for live hardware, workspace, and media reactivity.

2. **Universal Image & Video Wallpapers**:
   - All pictures (`.png`, `.jpg`, `.webp`) and animated videos (`.mp4`, `.webm`) from `~/Pictures/Wallpapers/` are loaded via a hardware-accelerated HTML5 viewer.
   - Live custom effects (particles, parallax, solar lighting, rain/snow, cyber HUD clock, vignette, scanlines) render directly over the wallpaper in real time.

3. **Solid Tokyo Night Canvas Colors**:
   - Clean, zero-CPU solid color backdrops.

### 2.2 CLI Controller (`wallpaperctl`)
- `wallpaperctl start | stop | restart | status | reload | init`
- `wallpaperctl set <path_or_theme>`
- `wallpaperctl color <#hex>`
- `wallpaperctl set-effect <key> <value>`
- `wallpaperctl random`

### 2.3 State Persistence
The active wallpaper target is saved to `~/.config/niri/current_wallpaper` and `quickshell/wallpaper-engine/config.json`, and restored on login via `wallpaperctl init &` in `niri/startup.sh`.
