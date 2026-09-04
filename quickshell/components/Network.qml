import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 30

    property string ssid: "Disconnected"

    Process {
        id: fetchProcess
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") {
                    root.ssid = out
                } else {
                    root.ssid = "Disconnected"
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: fetchProcess.running = true
    }

    Row {
        id: row
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
            text: root.ssid === "Disconnected" ? "󰤭" : "󰤨"
            color: root.ssid === "Disconnected" ? "#f7768e" : "#7aa2f7"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.ssid
            color: "#c0caf5"
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
