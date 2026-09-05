import QtQuick
import "../config.js" as Config

// Weather-reactive particle overlay (optional)
// Rain: thin falling lines | Snow: drifting white dots | Fog: gradient overlay
// Disabled by default — enable in config.js and provide weather data.
Item {
    id: root
    anchors.fill: parent
    visible: Config.weatherEnabled
    clip: true

    // Weather condition from environment data
    property string condition: ""  // "Rain", "Snow", "Fog", "Mist", "Drizzle", "Clear", "Clouds"

    property bool isRain: condition === "Rain" || condition === "Drizzle" || condition === "Thunderstorm"
    property bool isSnow: condition === "Snow"
    property bool isFog: condition === "Fog" || condition === "Mist" || condition === "Haze"

    // Rain particles
    Repeater {
        model: root.isRain ? Config.rainParticleCount : 0

        delegate: Rectangle {
            property real startX: Math.random() * root.width
            property real fallDuration: 600 + Math.random() * 800

            width: 1
            height: 12 + Math.random() * 18
            radius: 0.5
            color: Config.colorAccentCyan
            opacity: 0.15 + Math.random() * 0.2
            x: startX + (Math.random() * 30 - 15)
            y: -height

            SequentialAnimation on y {
                loops: Animation.Infinite
                running: root.isRain && root.visible

                NumberAnimation {
                    from: -30
                    to: root.height + 30
                    duration: fallDuration
                    easing.type: Easing.Linear
                }
                PauseAnimation {
                    duration: Math.random() * 300
                }
            }

            // Slight wind angle via horizontal drift
            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.isRain && root.visible

                NumberAnimation {
                    from: startX
                    to: startX + 20 + Math.random() * 40
                    duration: fallDuration
                    easing.type: Easing.Linear
                }
                NumberAnimation {
                    from: startX
                    to: startX
                    duration: 0
                }
            }
        }
    }

    // Snow particles
    Repeater {
        model: root.isSnow ? Config.snowParticleCount : 0

        delegate: Rectangle {
            property real startX: Math.random() * root.width
            property real startY: -10 - Math.random() * 50
            property real fallDuration: 5000 + Math.random() * 8000
            property real swayAmount: 30 + Math.random() * 60
            property real dotSize: 2 + Math.random() * 4

            width: dotSize
            height: dotSize
            radius: dotSize / 2
            color: "#ffffff"
            opacity: 0.3 + Math.random() * 0.4
            x: startX
            y: startY

            // Falling
            SequentialAnimation on y {
                loops: Animation.Infinite
                running: root.isSnow && root.visible

                NumberAnimation {
                    from: startY
                    to: root.height + 20
                    duration: fallDuration
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: Math.random() * 1000 }
            }

            // Horizontal sway
            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.isSnow && root.visible

                NumberAnimation {
                    from: startX - swayAmount / 2
                    to: startX + swayAmount / 2
                    duration: fallDuration / 3
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: startX + swayAmount / 2
                    to: startX - swayAmount / 2
                    duration: fallDuration / 3
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    // Fog / Mist overlay
    Rectangle {
        visible: root.isFog
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.35
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.6; color: Qt.rgba(0.1, 0.11, 0.15, 0.15) }
            GradientStop { position: 1.0; color: Qt.rgba(0.1, 0.11, 0.15, 0.3) }
        }

        // Subtle fog drift animation
        opacity: 1.0
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: root.isFog && root.visible
            NumberAnimation { to: 0.7; duration: 6000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 6000; easing.type: Easing.InOutSine }
        }
    }
}
