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

    function loadThemeJson(raw) {
        try {
            if (!raw || raw.trim() === "") return
            let d = JSON.parse(raw.trim())
            if (d.id) root.themeId = d.id
            if (d.name) root.name = d.name
            if (d.description !== undefined) root.description = d.description
            if (d.wallpaper) root.wallpaper = d.wallpaper

            if (d.bg) root.bg = d.bg
            if (d.bg_alpha) root.bgAlpha = d.bg_alpha
            if (d.bg_alt) root.bgAlt = d.bg_alt
            if (d.surface) root.surface = d.surface
            if (d.surface_hover) root.surfaceHover = d.surface_hover
            if (d.surface_card) root.surfaceCard = d.surface_card

            if (d.accent) root.accent = d.accent
            if (d.accent_secondary) root.accentSecondary = d.accent_secondary
            if (d.accent_tertiary) root.accentTertiary = d.accent_tertiary

            if (d.border) root.border = d.border
            if (d.border_active) root.borderActive = d.border_active

            if (d.fg) root.fg = d.fg
            if (d.fg_secondary) root.fgSecondary = d.fg_secondary
            if (d.fg_muted) root.fgMuted = d.fg_muted

            if (d.success) root.success = d.success
            if (d.warning) root.warning = d.warning
            if (d.danger) root.danger = d.danger
        } catch(e) {}
    }

    function loadBarStyleJson(raw) {
        try {
            if (!raw || raw.trim() === "") return
            let d = JSON.parse(raw.trim())
            if (d.style && d.style !== "") {
                root.barStyle = d.style
            }
        } catch(e) {}
    }

    function refresh() {
        themeFile.reload()
        barFile.reload()
        themeProcess.running = true
        barStyleProcess.running = true
    }

    // Instant File-based State Watchers (loads on startup and on disk changes)
    property var themeFile: FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme.json"
        preload: true
        watchChanges: true
        onLoaded: root.loadThemeJson(text())
        onFileChanged: reload()
    }

    property var barFile: FileView {
        id: barFile
        path: Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bar_style.json"
        preload: true
        watchChanges: true
        onLoaded: root.loadBarStyleJson(text())
        onFileChanged: reload()
    }

    property var proc: Process {
        id: themeProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme-manager", "current"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.loadThemeJson(text)
        }
    }

    property var barProc: Process {
        id: barStyleProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme-manager", "bar-style", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.loadBarStyleJson(text)
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
