# 🖥️ Display & Wallpaper Management Subsystem

This document details display backlight control and the multi-mode wallpaper management engine.

---

## 1. Backlight Control

- **CLI Tool**: `brightnessctl`
- **Adjustment**: Increments/decrements in 5% steps via `niri/osd.sh bri-up` and `bri-down`.
- **Slider**: Controlled via `brightnessctl set <val>%` in `Settings.qml`.

---

## 2. Wallpaper Engine (`quickshell/wallpaper.sh`)

Supports three distinct wallpaper modes:

### 2.1 Static Images
- **Tool**: QuickShell native `WallpaperWindow` (QML)
- **Supported Formats**: JPG, JPEG, PNG, WEBP.

### 2.2 Live Video Wallpapers
- **Tool**: `mpvpaper -o "no-audio loop pause=no" '*' <path> &`
- **Supported Formats**: MP4, WEBM, GIF, MKV.
- **Thumbnail Generation**: Automatically generated and cached in `~/.cache/wallpaper_thumbnails/` using `ffmpegthumbnailer` or `ffmpeg`.

### 2.3 Canvas Solid Colors
- **Tool**: QuickShell native `WallpaperWindow` (QML)
- **Purpose**: Low-resource solid color backgrounds for minimal distraction.

### 2.4 State Persistence
The active wallpaper or color is saved to `~/.config/niri/current_wallpaper` and restored on login via `wallpaper.sh init`.
