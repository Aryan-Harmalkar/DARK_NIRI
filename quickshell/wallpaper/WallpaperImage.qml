import QtQuick
import "config.js" as Config

// Dual-image crossfade wallpaper renderer
// Stacks two Image items; on wallpaper change, the back image loads the new
// source, then opacity crossfades from front to back.
Item {
    id: root
    anchors.fill: parent

    // The current wallpaper path (file path string)
    property string wallpaperPath: ""
    // Solid color mode (when wallpaperPath starts with "color:")
    property string solidColor: ""
    // Parallax offset from ParallaxLayer
    property real offsetX: 0
    property real offsetY: 0

    // Internal: which layer is "front" (visible)
    property bool frontIsA: true

    onWallpaperPathChanged: {
        if (wallpaperPath === "") return

        if (wallpaperPath.indexOf("color:") === 0) {
            root.solidColor = wallpaperPath.substring(6)
            imageA.source = ""
            imageB.source = ""
            return
        }

        root.solidColor = ""
        let newSource = "file://" + wallpaperPath

        if (frontIsA) {
            imageB.source = newSource
        } else {
            imageA.source = newSource
        }
    }

    // Solid color backdrop
    Rectangle {
        anchors.fill: parent
        color: root.solidColor !== "" ? root.solidColor : "transparent"
        visible: root.solidColor !== ""

        Behavior on color {
            ColorAnimation { duration: Config.crossfadeDuration }
        }
    }

    // Layer A
    Image {
        id: imageA
        anchors.centerIn: parent
        width: parent.width + (Config.parallaxEnabled ? Config.parallaxMaxShift * 2 : 0)
        height: parent.height + (Config.parallaxEnabled ? Config.parallaxMaxShift * 2 : 0)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: source != ""
        opacity: root.frontIsA ? 1.0 : 0.0
        transform: Translate {
            x: Config.parallaxEnabled ? root.offsetX : 0
            y: Config.parallaxEnabled ? root.offsetY : 0
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Config.crossfadeDuration
                easing.type: Easing.InOutQuad
            }
        }

        onStatusChanged: {
            if (status === Image.Ready && !root.frontIsA) {
                root.frontIsA = true
            }
        }
    }

    // Layer B
    Image {
        id: imageB
        anchors.centerIn: parent
        width: parent.width + (Config.parallaxEnabled ? Config.parallaxMaxShift * 2 : 0)
        height: parent.height + (Config.parallaxEnabled ? Config.parallaxMaxShift * 2 : 0)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: source != ""
        opacity: root.frontIsA ? 0.0 : 1.0
        transform: Translate {
            x: Config.parallaxEnabled ? root.offsetX : 0
            y: Config.parallaxEnabled ? root.offsetY : 0
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Config.crossfadeDuration
                easing.type: Easing.InOutQuad
            }
        }

        onStatusChanged: {
            if (status === Image.Ready && root.frontIsA) {
                root.frontIsA = false
            }
        }
    }
}
