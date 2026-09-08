# 🌐 HTML/Web Wallpaper Engine for Niri & Wayland

DARK_NIRI features a modular, hardware-accelerated **HTML/Web Wallpaper Engine** built specifically for Arch Linux, Wayland, and the Niri scrollable tiling compositor.

It renders interactive HTML5, CSS3, JavaScript, Canvas, and WebGL wallpapers natively behind all application windows using `gtk4-layer-shell` and `webkitgtk-6.0`.

---

## 1. Architecture Overview

```
                      Niri Compositor (Wayland)
                                  │
      ┌───────────────────────────┴───────────────────────────┐
      │                                                       │
 Application Windows                                      Layer Shell
 (Firefox, Alacritty, etc.)                                   │
                                            ┌─────────────────┴─────────────────┐
                                            │                                   │
                                    Layer: Top Bar                     Layer: Background
                                 (QuickShell shell.qml)             (Wallpaper Engine App)
                                            │                                   │
                                 ┌──────────┴──────────┐            ┌───────────┴───────────┐
                                 │ QuickShell Settings │            │ GTK4 + Gtk4LayerShell │
                                 │   Studio Modal      │            │ WebKitGTK 6.0 WebView │
                                 └──────────┬──────────┘            └───────────┬───────────┘
                                            │                                   │
                                      UNIX Domain Socket ◄──────────────────────┤
                                (/tmp/qs-wallpaper-$UID.sock)                   │
                                                                                ▼
                                                                      HTML/CSS/JS/WebGL Theme
                                                                      + window.wallpaper API
```

### Key Architectural Highlights:
1. **Isolated Stability**: The WebKit renderer runs in a dedicated background process. A wallpaper crash will **never** bring down QuickShell, Niri, notifications, or other desktop components.
2. **True Wayland Layer Shell**: Renders on `Layer.BACKGROUND` with `KeyboardMode.NONE`. It never steals keyboard focus or intercepts Niri shortcuts.
3. **GPU Accelerated**: Configured with `WebKit.HardwareAccelerationPolicy.ALWAYS` and WebGL enabled for smooth 60–144 FPS rendering with minimal CPU overhead.
4. **Sandboxed Security**: Web wallpapers cannot execute arbitrary shell commands or access private system files. Desktop telemetry is passed safely through the strictly controlled `window.wallpaper` bridge API.
5. **Universal Image & Video Wrapper**: Standard pictures and animated videos (`.mp4`, `.webm`) are automatically hosted within a GPU-accelerated HTML5 viewer supporting real-time particle, parallax, weather, and HUD overlays.

---

## 2. Directory Structure

The wallpaper subsystem is located in `quickshell/wallpaper-engine/`:

```
quickshell/wallpaper-engine/
├── engine.py                   # Authoritative GTK4 Layer Shell + WebKit engine
├── wallpaperctl                # Command-line controller & IPC client
├── config.json                 # Persistent engine configuration & effect state
├── quickshell-wallpaper.service# Systemd user service unit
└── themes/                     # Self-contained web wallpapers
    ├── cyber-city/             # Animated cyberpunk metropolis with skyline & HUD
    ├── aurora/                 # Fluid northern lights ribbons
    ├── cyber-matrix/           # Tokyo Night digital code stream
    ├── particles/              # Interactive constellation particle network
    ├── waves/                  # Layered harmonic sine waves
    ├── fallback/               # Safe Tokyo Night radial gradient
    └── image-viewer/           # Universal wrapper for images & videos with live FX
```

---

## 3. Creating a Custom Web Wallpaper

Every web wallpaper is a self-contained directory containing an `index.html` and a `wallpaper.json` manifest.

### Minimal Example Wallpaper:
Create a directory in `quickshell/wallpaper-engine/themes/my-wallpaper/`:

#### `wallpaper.json`
```json
{
  "name": "My Animated Theme",
  "version": "1.0",
  "author": "Local",
  "entry": "index.html",
  "description": "Custom interactive canvas wallpaper",
  "fps": 60,
  "interactive": true,
  "audioReactive": false,
  "multiMonitor": true
}
```

#### `index.html`
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <style>
    * { margin: 0; padding: 0; overflow: hidden; }
    body { width: 100vw; height: 100vh; background: #1a1b26; }
    canvas { width: 100%; height: 100%; display: block; }
  </style>
</head>
<body>
  <canvas id="c"></canvas>
  <script src="script.js"></script>
</body>
</html>
```

#### `script.js`
```javascript
const canvas = document.getElementById('c');
const ctx = canvas.getContext('2d');
let w = canvas.width = window.innerWidth;
let h = canvas.height = window.innerHeight;

window.addEventListener('resize', () => {
  w = canvas.width = window.innerWidth;
  h = canvas.height = window.innerHeight;
});

// React to desktop events using the sandbox bridge
if (window.wallpaper) {
  window.wallpaper.on('telemetry', (data) => {
    console.log("CPU:", data.cpu, "RAM:", data.memory);
  });
}

function render() {
  ctx.fillStyle = 'rgba(26, 27, 38, 0.1)';
  ctx.fillRect(0, 0, w, h);
  requestAnimationFrame(render);
}
render();
```

---

## 4. Sandboxed JavaScript Bridge API (`window.wallpaper`)

The engine automatically injects the `window.wallpaper` object into every loaded page:

### Desktop Telemetry
- `wallpaper.getBattery()` -> `{ percentage: 85, charging: true }`
- `wallpaper.getCpuUsage()` -> `12` (integer percentage 0-100)
- `wallpaper.getMemoryUsage()` -> `34` (integer percentage 0-100)
- `wallpaper.getActiveWorkspace()` -> `{ id: 1, idx: 1 }`
- `wallpaper.getMusic()` -> `{ title: "Song Name", artist: "Artist", status: "Playing" }`
- `wallpaper.getMonitor()` -> `"eDP-1"`

### Object Namespaces
- `wallpaper.system.battery()`
- `wallpaper.system.cpu()`
- `wallpaper.system.memory()`
- `wallpaper.system.time()`
- `wallpaper.desktop.workspace()`
- `wallpaper.desktop.monitors()`
- `wallpaper.media.player()`

### Event Subscriptions
```javascript
wallpaper.on("battery", (data) => {
  console.log("Battery level:", data.percentage);
});

wallpaper.on("telemetry", (data) => {
  console.log("CPU:", data.cpu, "RAM:", data.memory);
});

wallpaper.on("workspace", (data) => {
  console.log("Switched to workspace:", data.idx);
});

wallpaper.on("media", (data) => {
  console.log("Now playing:", data.title, "by", data.artist);
});
```

---

## 5. Command-Line Interface (`wallpaperctl`)

The `wallpaperctl` utility provides complete control over the wallpaper engine:

| Command | Description |
| :--- | :--- |
| `wallpaperctl start` | Starts the engine daemon if not running |
| `wallpaperctl stop` | Stops the engine daemon cleanly |
| `wallpaperctl restart` | Restarts the engine daemon |
| `wallpaperctl status` | Shows engine status, PID, monitors, active target, and effects |
| `wallpaperctl list` | Returns a JSON list of all available themes and wallpapers |
| `wallpaperctl set <theme_or_path>` | Applies a web theme or wallpaper image/video |
| `wallpaperctl set <theme_or_path> <mon>`| Sets wallpaper on a specific display (e.g. `eDP-1`) |
| `wallpaperctl color <#hex>` | Sets a solid Tokyo Night canvas background |
| `wallpaperctl set-effect <key> <val>` | Dynamically tunes effects live (e.g. `particles.count 60`) |
| `wallpaperctl random` | Picks and applies a random wallpaper or theme |
| `wallpaperctl reload` | Reloads the webview across all displays |
| `wallpaperctl init` | Restores the saved wallpaper upon login |

---

## 6. QuickShell Settings GUI Studio

Click the **Gear icon** on the top bar or open Control Center -> **Web Wallpaper Studio**:

1. **Web Themes Tab**: Interactive card gallery showing all self-contained web themes with badges (`Interactive`, `WebGL`).
2. **Wallpapers Tab**: Browse your local wallpaper pictures and animated videos from `~/Pictures/Wallpapers/`.
3. **Effects & FX Customizer**:
   - **Floating Particles**: Toggle on/off, choose style (`Embers`, `Dust`, `Nodes`), count (`20`, `40`, `80`, `120`), and color presets.
   - **Mouse Parallax**: Toggle on/off, select depth intensity (`Subtle 1.5x`, `Normal 2.5x`, `Dynamic 4.0x`).
   - **Time-of-Day Lighting**: Solar color grading (`Auto`, `Dawn`, `Day`, `Sunset`, `Night`).
   - **Weather Overlay**: Realistic procedural rain or snow simulation.
   - **Cyber HUD Clock**: On-screen digital time and date HUD (`Top-Right`, `Top-Left`, `Center`, 24h, Seconds).
   - **Scanlines & Vignette**: CRT phosphor lines and edge shadowing.
   - **Post-Processing**: Hardware blur, brightness, and contrast.
4. **Performance & Profiles**:
   - Profiles: `Battery Saver` (30 FPS, Minimal FX), `Balanced` (60 FPS), `Performance` (120+ FPS).
   - Intelligent Fullscreen Pause toggle (auto-pauses when a fullscreen game/app covers the monitor).
   - Laptop Battery Throttle toggle.
   - Telemetry monitoring and quick actions (`Reload`, `Restart`, `Random`).
5. **Canvas Colors Tab**: Palette of solid Tokyo Night backgrounds.

---

## 7. Multi-Monitor & Hotplug

- Automatically detects all connected Wayland monitors (`eDP-1`, `HDMI-A-1`, `DP-1`).
- Dynamic hotplug: connecting a new monitor creates a wallpaper layer surface immediately without restarting QuickShell. Disconnecting cleans up resources automatically.
- Supports both **Global Mode** (same wallpaper on all displays) and **Per-Monitor Mode** (different wallpapers assigned to individual outputs).

---

## 8. Low-Overhead Architecture & Performance Tuning

The engine is engineered for ultra-low resource consumption on Arch Linux with hybrid GPU hardware (AMD + NVIDIA):

- **OpenGL Renderer (`GSK_RENDERER=gl`)**: Bypasses the GTK4 Vulkan swapchain spin-lock on Wayland, preventing thread pool busy-waiting.
- **Document Viewer Cache Model**: Employs `WebKit.CacheModel.DOCUMENT_VIEWER`, disabling multi-megabyte browsing history caches and page caches.
- **Native GLib Timer**: Telemetry sampling runs at a gentle 2-second cadence with zero idle-loop spin.
- **Dynamic Render Throttling**: All theme and effect canvas loops throttle animation to the target FPS (30 FPS on battery saver, 60 FPS on balanced, 120 FPS on performance).
- **Intelligent Fullscreen Pause**: Automatically suspends render loops when an active window covers the display.
- **Instant Optimistic Reactivity**: QuickShell Settings updates state instantaneously in QML before asynchronous IPC commits, delivering snappy 60fps toggle animations.
