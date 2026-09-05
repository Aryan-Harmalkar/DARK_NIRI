import QtQuick
import "../config.js" as Config

// Mouse-reactive parallax depth effect
// Tracks mouse position and provides offset values to shift the wallpaper image
// subtly, creating a perception of depth.
Item {
    id: root
    anchors.fill: parent
    visible: Config.parallaxEnabled

    // Output: offset values for WallpaperImage to consume
    property real offsetX: 0
    property real offsetY: 0

    // Internal mouse tracking
    property real mouseNormX: 0.5  // 0.0 = left, 1.0 = right
    property real mouseNormY: 0.5  // 0.0 = top, 1.0 = bottom
    property real targetX: 0
    property real targetY: 0

    // Smooth easing on offset output
    Behavior on offsetX {
        NumberAnimation {
            duration: Config.parallaxSmoothing
            easing.type: Easing.OutCubic
        }
    }

    Behavior on offsetY {
        NumberAnimation {
            duration: Config.parallaxSmoothing
            easing.type: Easing.OutCubic
        }
    }

    // Idle timer — settle back to center after mouse stops
    Timer {
        id: idleTimer
        interval: Config.parallaxIdleTimeout
        repeat: false
        onTriggered: {
            root.offsetX = 0
            root.offsetY = 0
        }
    }

    // Mouse area covers entire wallpaper
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Don't consume clicks

        onPositionChanged: (mouse) => {
            if (!Config.parallaxEnabled) return
            if (root.width <= 0 || root.height <= 0) return

            root.mouseNormX = mouse.x / root.width
            root.mouseNormY = mouse.y / root.height

            // Map normalized mouse position to offset
            // Center (0.5, 0.5) = no offset
            root.offsetX = (0.5 - root.mouseNormX) * Config.parallaxMaxShift * 2
            root.offsetY = (0.5 - root.mouseNormY) * Config.parallaxMaxShift * 2

            idleTimer.restart()
        }
    }
}
