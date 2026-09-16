pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string themeId: "tokyo-night"
    property string name: "Tokyo Night"
    property string description: "Signature dark cyberpunk neon"
    property string wallpaper: "cyber-city"

    // Backgrounds & Surfaces
    property string bg: "#1a1b26"
    property string bgAlpha: "#E61a1b26"
    property string bgAlt: "#24283b"
    property string surface: "#1f2335"
    property string surfaceHover: "#292e42"
    property string surfaceCard: "#24283b"

    // Accents
    property string accent: "#7aa2f7"
    property string accentSecondary: "#bb9af7"
    property string accentTertiary: "#7dcfff"

    // Borders
    property string border: "#292e42"
    property string borderActive: "#7aa2f7"

    // Text
    property string fg: "#c0caf5"
    property string fgSecondary: "#a9b1d6"
    property string fgMuted: "#565f89"

    // Status
    property string success: "#9ece6a"
    property string warning: "#e0af68"
    property string danger: "#f7768e"

    // Bar Style: floating | islands | normal | compact
    property string barStyle: "floating"

    function setBarStyle(newStyle) {
        root.barStyle = newStyle
        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme-manager", "bar-style", "set", newStyle])
    }

    function refresh() {
        themeProcess.running = true
        barStyleProcess.running = true
    }

    property var proc: Process {
        id: themeProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme-manager", "current"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text.trim())
                    root.themeId = d.id || "tokyo-night"
                    root.name = d.name || "Tokyo Night"
                    root.description = d.description || ""
                    root.wallpaper = d.wallpaper || "cyber-city"

                    root.bg = d.bg || "#1a1b26"
                    root.bgAlpha = d.bg_alpha || "#E61a1b26"
                    root.bgAlt = d.bg_alt || "#24283b"
                    root.surface = d.surface || "#1f2335"
                    root.surfaceHover = d.surface_hover || "#292e42"
                    root.surfaceCard = d.surface_card || "#24283b"

                    root.accent = d.accent || "#7aa2f7"
                    root.accentSecondary = d.accent_secondary || "#bb9af7"
                    root.accentTertiary = d.accent_tertiary || "#7dcfff"

                    root.border = d.border || "#292e42"
                    root.borderActive = d.border_active || "#7aa2f7"

                    root.fg = d.fg || "#c0caf5"
                    root.fgSecondary = d.fg_secondary || "#a9b1d6"
                    root.fgMuted = d.fg_muted || "#565f89"

                    root.success = d.success || "#9ece6a"
                    root.warning = d.warning || "#e0af68"
                    root.danger = d.danger || "#f7768e"
                } catch(e) {}
            }
        }
    }

    property var barProc: Process {
        id: barStyleProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme-manager", "bar-style", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text.trim())
                    if (d.style && d.style !== "") {
                        root.barStyle = d.style
                    }
                } catch(e) {}
            }
        }
    }

    property var checkTimer: Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: {
            themeProcess.running = true
            barStyleProcess.running = true
        }
    }
}
