import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 30

    property string brightnessLevel: "0%"

    Process {
        id: fetchProcess
        command: ["sh", "-c", "brightnessctl -m | awk -F, '{print $4}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    root.brightnessLevel = text.trim()
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: fetchProcess.running = true
    }

    Process {
        id: incBright
        command: ["brightnessctl", "set", "5%+"]
    }

    Process {
        id: decBright
        command: ["brightnessctl", "set", "5%-"]
    }

    Row {
        id: row
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
            text: "󰃠"
            color: "#e0af68"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.brightnessLevel
            color: "#c0caf5"
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                incBright.running = true
            } else {
                decBright.running = true
            }
            // Trigger an immediate update
            fetchProcess.running = true
        }
    }
}
