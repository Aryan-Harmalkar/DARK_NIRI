import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 30

    property string volumeLevel: "0%"
    property bool isMuted: false

    Process {
        id: fetchProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") {
                    let parts = out.split(" ")
                    if (parts.length >= 2) {
                        let vol = parseFloat(parts[1]) * 100
                        root.volumeLevel = Math.round(vol) + "%"
                        root.isMuted = out.indexOf("[MUTED]") !== -1
                    }
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
        id: toggleMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Process {
        id: incVol
        command: ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"]
    }

    Process {
        id: decVol
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
    }

    Row {
        id: row
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
            text: root.isMuted ? "󰖁" : "󰕾"
            color: root.isMuted ? "#f7768e" : "#9ece6a"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.volumeLevel
            color: "#c0caf5"
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            toggleMute.running = true
            fetchProcess.running = true
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                incVol.running = true
            } else {
                decVol.running = true
            }
            fetchProcess.running = true
        }
    }
}
