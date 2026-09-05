import QtQuick
import "../config.js" as Config

// Floating ambient particles
// Pure QML — no QtQuick.Particles dependency.
// Spawns soft translucent circles that drift slowly across the screen.
// At night, particles become small twinkling "stars".
Item {
    id: root
    anchors.fill: parent
    visible: Config.particlesEnabled

    property int currentHour: new Date().getHours()
    property bool isNight: currentHour >= 20 || currentHour < 6

    readonly property var dayColors: [
        Config.colorAccent,
        Config.colorAccentPurple,
        Config.colorAccentCyan,
        Config.colorAccentGreen
    ]
    readonly property var nightColors: [
        "#ffffff",
        Config.colorAccentCyan,
        Config.colorAccent,
        "#e0e0e0"
    ]

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            root.currentHour = new Date().getHours()
            root.isNight = (root.currentHour >= 20 || root.currentHour < 6)
        }
    }

    Repeater {
        model: Config.particleCount

        delegate: Rectangle {
            id: particle

            property real randSeed: Math.random()
            property real particleSize: root.isNight
                ? (Config.particleMinSize * 0.6 + Math.random() * Config.particleMinSize * 0.4)
                : (Config.particleMinSize + Math.random() * (Config.particleMaxSize - Config.particleMinSize))
            property real driftDuration: Config.particleMinDuration + Math.random() * (Config.particleMaxDuration - Config.particleMinDuration)
            property real startX: Math.random() * root.width
            property real startY: Math.random() * root.height
            property real endX: Math.random() * root.width
            property real endY: Math.random() * root.height
            property real baseOpacity: root.isNight
                ? (0.15 + Math.random() * 0.35)
                : (Config.particleMinOpacity + Math.random() * (Config.particleMaxOpacity - Config.particleMinOpacity))

            width: particleSize
            // Keep height and radius bound to width for circle shape
            height: width
            radius: width / 2
            color: {
                let palette = root.isNight ? root.nightColors : root.dayColors
                return palette[index % palette.length]
            }
            opacity: baseOpacity
            x: startX
            y: startY

            // Horizontal drift
            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation {
                    to: particle.endX
                    duration: particle.driftDuration
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: particle.startX
                    duration: particle.driftDuration * 0.8
                    easing.type: Easing.InOutSine
                }
            }

            // Vertical drift
            SequentialAnimation on y {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation {
                    to: particle.endY
                    duration: particle.driftDuration * 1.1
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: particle.startY
                    duration: particle.driftDuration * 0.9
                    easing.type: Easing.InOutSine
                }
            }

            // Breathing / twinkle opacity
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation {
                    to: particle.baseOpacity * (root.isNight ? 0.2 : 0.4)
                    duration: root.isNight ? (1000 + particle.randSeed * 2000) : (particle.driftDuration * 0.5)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: particle.baseOpacity
                    duration: root.isNight ? (800 + particle.randSeed * 1500) : (particle.driftDuration * 0.5)
                    easing.type: Easing.InOutSine
                }
            }

            // Subtle size pulse (day only)
            SequentialAnimation on width {
                loops: Animation.Infinite
                running: root.visible && !root.isNight
                NumberAnimation {
                    to: particle.particleSize * 1.3
                    duration: particle.driftDuration * 0.6
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: particle.particleSize
                    duration: particle.driftDuration * 0.6
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
