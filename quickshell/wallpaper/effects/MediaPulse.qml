import QtQuick
import "../config.js" as Config

// Music-reactive ambient edge glow
// When media is playing, a subtle vignette glow pulses around the screen edges.
// Paused = glow freezes at low opacity. Stopped = glow fades out.
Item {
    id: root
    anchors.fill: parent
    visible: Config.mediaPulseEnabled

    // Media state from parent
    property string mediaStatus: "Stopped"  // "Playing", "Paused", "Stopped"

    property real glowOpacity: 0.0
    property real pulseTarget: 0.0

    onMediaStatusChanged: {
        if (mediaStatus === "Playing") {
            pulseAnim.running = true
        } else if (mediaStatus === "Paused") {
            pulseAnim.running = false
            root.glowOpacity = Config.mediaPulseMaxOpacity * 0.4
        } else {
            pulseAnim.running = false
            root.glowOpacity = 0.0
        }
    }

    // Pulse animation
    SequentialAnimation {
        id: pulseAnim
        loops: Animation.Infinite
        running: false

        NumberAnimation {
            target: root
            property: "glowOpacity"
            from: Config.mediaPulseMaxOpacity * 0.3
            to: Config.mediaPulseMaxOpacity
            duration: Config.mediaPulseDuration / 2
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "glowOpacity"
            from: Config.mediaPulseMaxOpacity
            to: Config.mediaPulseMaxOpacity * 0.3
            duration: Config.mediaPulseDuration / 2
            easing.type: Easing.InOutSine
        }
    }

    Behavior on glowOpacity {
        NumberAnimation {
            duration: 800
            easing.type: Easing.InOutQuad
        }
    }

    // Top edge glow
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.15
        opacity: root.glowOpacity
        gradient: Gradient {
            GradientStop { position: 0.0; color: Config.colorAccent }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Bottom edge glow
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.15
        opacity: root.glowOpacity
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Config.colorAccentPurple }
        }
    }

    // Left edge glow
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width * 0.08
        opacity: root.glowOpacity
        rotation: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Config.colorAccent }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Right edge glow
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: parent.width * 0.08
        opacity: root.glowOpacity
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Config.colorAccentPurple }
        }
    }
}
