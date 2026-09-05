import QtQuick
import "../config.js" as Config

// Time-of-day color temperature overlay
// Applies a subtle tinted overlay that shifts based on the current hour.
// Dawn: warm gold | Day: transparent | Dusk: amber | Night: cool blue
Rectangle {
    id: root
    anchors.fill: parent
    visible: Config.timeOverlayEnabled

    // Start transparent
    color: "transparent"
    opacity: 0.0

    // Current hour fed from internal timer
    property int currentHour: new Date().getHours()

    function updateTimeState() {
        let h = new Date().getHours()
        root.currentHour = h

        if (h >= 5 && h < 7) {
            // Dawn — warm golden
            root.color = Config.colorAccentOrange
            root.opacity = 0.04
        } else if (h >= 7 && h < 17) {
            // Day — no overlay
            root.color = "transparent"
            root.opacity = 0.0
        } else if (h >= 17 && h < 20) {
            // Dusk — warm amber
            root.color = Config.colorAccentYellow
            root.opacity = 0.06
        } else {
            // Night — cool blue
            root.color = Config.colorAccent
            root.opacity = 0.08
        }
    }

    Component.onCompleted: updateTimeState()

    Timer {
        interval: Config.timeUpdateInterval
        running: Config.timeOverlayEnabled
        repeat: true
        onTriggered: root.updateTimeState()
    }

    Behavior on color {
        ColorAnimation { duration: Config.timeTransitionDuration }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Config.timeTransitionDuration
            easing.type: Easing.InOutSine
        }
    }
}
