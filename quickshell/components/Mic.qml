import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 30

    property bool isMuted: false

    Process {
        id: fetchProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") {
                    root.isMuted = out.indexOf("[MUTED]") !== -1
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
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    Row {
        id: row
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
            text: root.isMuted ? "󰍭" : "󰍬"
            color: root.isMuted ? "#f7768e" : "#c0caf5"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            toggleMute.running = true
            fetchProcess.running = true
        }
    }
}
