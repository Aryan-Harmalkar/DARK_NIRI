import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "wallpaper" as Wallpaper
import "wallpaper/effects" as Effects
import "wallpaper/config.js" as Config

// Main interactive wallpaper window
// Renders on WlrLayer.Background behind all windows.
// Hosts the crossfade image renderer and all visual effect layers.
PanelWindow {
    id: wallpaperRoot

    // Place on the background layer (behind everything)
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "dark-niri-wallpaper"

    // Cover the entire screen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // No exclusive zone — don't push windows
    color: "#1a1b26"

    // Current wallpaper path
    property string currentWallpaper: ""
    // Media status
    property string mediaStatus: "Stopped"
    // Weather condition
    property string weatherCondition: ""

    // Read current wallpaper from state file on startup
    Process {
        id: getWallpaper
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper.sh", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let path = text.trim()
                if (path !== "") {
                    wallpaperRoot.currentWallpaper = path
                }
            }
        }
    }

    // Poll for wallpaper changes (watches state file)
    Timer {
        id: wallpaperPollTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: getWallpaper.running = true
    }

    // Environment data provider (time, media, weather)
    Process {
        id: envProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-env.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(text.trim())
                    wallpaperRoot.mediaStatus = data.media_status || "Stopped"
                    wallpaperRoot.weatherCondition = data.weather || ""
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: Config.mediaCheckInterval
        running: true
        repeat: true
        onTriggered: envProcess.running = true
    }

    // ──── Visual Layer Stack ────
    // Order: Image → Time → Particles → MediaPulse → Weather
    // ParallaxLayer provides offset data to WallpaperImage

    // 1. Crossfade wallpaper image renderer
    Wallpaper.WallpaperImage {
        id: wallpaperImage
        anchors.fill: parent
        wallpaperPath: wallpaperRoot.currentWallpaper
        offsetX: parallaxEffect.offsetX
        offsetY: parallaxEffect.offsetY
    }

    // 2. Time-of-day color overlay
    Effects.TimeOverlay {
        anchors.fill: parent
    }

    // 3. Floating ambient particles
    Effects.ParticleLayer {
        anchors.fill: parent
    }

    // 4. Music-reactive edge glow
    Effects.MediaPulse {
        anchors.fill: parent
        mediaStatus: wallpaperRoot.mediaStatus
    }

    // 5. Weather-reactive overlay (optional)
    Effects.WeatherOverlay {
        anchors.fill: parent
        condition: wallpaperRoot.weatherCondition
    }

    // 6. Parallax depth tracker (transparent — provides offset data only)
    Effects.ParallaxLayer {
        id: parallaxEffect
        anchors.fill: parent
    }
}
