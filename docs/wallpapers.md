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
├── wallpaper-engine            # Native Rust GTK4 Layer Shell + WebKit6 engine (from dark-tools-rs)
├── wallpaperctl                # Command-line controller CLI
├── wp-ipc                      # Native Rust IPC client & theme scanner binary
├── config.json                 # Persistent engine configuration & effect state
├── quickshell-wallpaper.service# Systemd user service unit
└── themes/                     # Self-contained web wallpapers
    ├── anime-sakura/           # Drifting cherry blossom petals with Mt. Fuji & warm lantern glow
    ├── anime-showcase/         # Interactive anime character showcase with auto-timer, stat cards & widgets
    ├── one-piece-crew/         # Animated One Piece Straw Hat crew showcase with 10 members in join order, live bounties & widgets
    ├── lofi-anime-room/        # Cozy anime study desk with ambient window rain & soft lighting
    ├── celestial-nebula/       # Deep cosmos with rotating galaxies, twinkling stars & nebula clouds
    ├── cyber-city/             # Animated cyberpunk metropolis with skyline & HUD
    ├── aurora/                 # Fluid northern lights ribbons
    ├── cyber-matrix/           # Tokyo Night digital code stream
    ├── particles/              # Interactive constellation particle network
    ├── waves/                  # Layered harmonic sine waves
    ├── fallback/               # Safe Tokyo Night radial gradient
    ├── image-viewer/           # Universal wrapper for images & videos with live FX
    ├── anime-3d-showcase/      # 3D Anime Cel-shaded procedural crystal with Niri parallax
    ├── html-wallpaper-template/# Reusable Three.js + Anime.js template with optimization
    ├── anime-pirate-crew/      # 3D Anime pirate ship & ocean with mouse parallax
    └── anime-cyberpunk-3d/     # 3D Neon cyberpunk city with glowing rain particles
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
| `wallpaperctl list` | Returns a JSON list of all available themes, wallpapers, and custom HTML items |
| `wallpaperctl set <theme_or_path_or_url>` | Applies a web theme, wallpaper image/video, or external HTML/URL |
| `wallpaperctl set <target> <mon>`| Sets wallpaper on a specific display (e.g. `eDP-1`) |
| `wallpaperctl add <path_or_url> [name]` | Registers an external HTML file or live web canvas into the gallery |
| `wallpaperctl remove <path_or_url>` | Removes a registered external HTML wallpaper from the gallery |
| `wallpaperctl color <#hex>` | Sets a solid Tokyo Night canvas background |
| `wallpaperctl set-effect <key> <val>` | Dynamically tunes effects live (e.g. `particles.count 60`) |
| `wallpaperctl random` | Picks and applies a random wallpaper or theme |
| `wallpaperctl reload` | Reloads the webview across all displays |
| `wallpaperctl init` | Restores the saved wallpaper upon login |

---

## 6. QuickShell Settings GUI Studio

Click the **Gear icon** on the top bar or open Control Center -> **Wallpaper Studio**:

1. **Master Engine ON/OFF Toggle**:
   - Integrated hardware toggle switch directly in the Settings Wallpaper tile banner and the Studio modal header.
   - Allows instant starting (`wallpaperctl start`) or graceful stopping (`wallpaperctl stop`) of the background engine process without touching the terminal.
2. **Web Themes Tab with Live Visual Previews**:
   - Interactive card gallery featuring rich graphical thumbnail previews (`preview.png`) for themes like **Anime Sakura**, **Lofi Anime Room**, and **Celestial Nebula**, with gradient fallback for abstract themes.
   - Shows badges (`INTERACTIVE`, `EXTERNAL HTML`, `WEB CANVAS`) and active checkmark indicator. Includes quick-action delete button for custom registered wallpapers.
3. **Add HTML Wallpaper Dialog**: Click `[+ Add HTML]` in the studio header to seamlessly import any local `.html` file or live WebGL canvas URL with instant registration.
4. **Wallpapers Tab**: Browse local wallpaper pictures and animated videos from `~/Pictures/Wallpapers/`.
5. **Zero SSD Wear Ephemeral Session**: Backed by `webkit6::NetworkSession::new_ephemeral()`, storing all HTML5 canvas buffers, caches, and DOM data strictly in RAM with 0 physical disk writes.
6. **Effects & FX Customizer**:
   - **Floating Particles**: Toggle on/off, choose style (`Embers`, `Dust`, `Nodes`), count (`20`, `40`, `80`, `120`), and color presets.
   - **Mouse Parallax**: Toggle on/off, select depth intensity (`Subtle 1.5x`, `Normal 2.5x`, `Dynamic 4.0x`).
   - **Time-of-Day Lighting**: Solar color grading (`Auto`, `Dawn`, `Day`, `Sunset`, `Night`).
   - **Weather Overlay**: Realistic procedural rain or snow simulation.
   - **Cyber HUD Clock**: On-screen digital time and date HUD (`Top-Right`, `Top-Left`, `Center`, 24h, Seconds).
   - **Scanlines & Vignette**: CRT phosphor lines and edge shadowing.
   - **Post-Processing**: Hardware blur, brightness, contrast.
   - **Color Saturation & Hue Rotation**: Saturation booster (`50%`, `100%`, `150%`, `200%`) and 360° chromatic hue rotator (`0°`, `90°`, `180°`, `270°`).
   - **Animation Speed Multiplier**: Global timescale controller for particle dynamics, weather physics, and shader motion (`0.5x`, `1.0x`, `1.5x`, `2.0x`).
   - **Interactive Click Ripples**: Spawns reactive pulsing energy wave ripples on desktop mouse clicks with selectable accent colors.
   - **Negative Invert Mode**: Cyberpunk inverted luminance styling (`Off`, `25%`, `50%`, `100%`).
7. **Performance & Engine Telemetry**:
   - Profiles: `Battery Saver` (30 FPS, Minimal FX), `Balanced` (60 FPS), `Performance` (120+ FPS).
   - **Framerate Limit (FPS)**: Dedicated refresh rate selector buttons (`30 FPS`, `60 FPS`, `90 FPS`, `120 FPS`, `144 FPS`) to optimize high-refresh gaming displays.
   - Intelligent Fullscreen Pause toggle (auto-pauses when a fullscreen game/app covers the monitor).
   - Laptop Battery Throttle toggle.
   - Telemetry monitoring and quick actions (`Reload`, `Restart`, `Random`).
8. **Canvas Colors Tab**: Palette of solid Tokyo Night backgrounds.

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

## 9. 3D WebGL Framework (Three.js + Anime.js)

The wallpaper engine features a heavily optimized, modular 3D framework for rendering interactive Wayland backgrounds without draining laptop batteries. 

### Architecture
- **`themes/shared/engine-core.js`**: A shared central module that abstracts WebGL initialization, `THREE.WebGLRenderer` context loss/restore, and memory disposal (`dispose()` calls on geometries, materials, and textures).
- **Offline First**: All libraries (`three.min.js`, `anime.min.js`) are bundled locally in `themes/shared/lib/`. No remote CDNs are required.

### Performance & Battery Profiles
The engine intelligently listens to `window.wallpaper.on('battery', ...)` and `window.__isWallpaperObscured`:
- **AC / High Performance**: 60+ FPS, high-resolution device pixel ratios.
- **Battery Saver (< 30%)**: Throttles `requestAnimationFrame` delta to 30 FPS, halves resolution, and disables expensive post-processing/particles.
- **Obscured State**: If Niri maximizes a window over the desktop, the WebGL render loop elegantly pauses to consume 0% GPU.

### Template & Theme Creation
To create a new 3D wallpaper, duplicate `themes/html-wallpaper-template`.
The template strictly separates logic into:
- `index.html` (Shell and UI overlays)
- `theme.js` (Three.js scene generation and Anime.js choreography)
- `wallpaper.json` (Quickshell Metadata)

### Agent Orchestration
This architecture was generated, built, and audited by a specialized multi-agent framework located in `.agents/`. The framework orchestrates `planner`, `designer`, `builder`, `tester`, and `review` agents to rigorously ensure zero memory leaks and Wayland compatibility.
