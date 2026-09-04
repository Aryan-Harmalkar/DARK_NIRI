import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 30

    property string capacity: "100"
    property string status: "Full"

    Process {
        id: fetchProcess
        command: ["sh", "-c", "echo $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null),$(cat /sys/class/power_supply/BAT*/status 2>/dev/null)"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                let parts = out.split(",")
                if (parts.length >= 2 && parts[0] !== "") {
                    root.capacity = parts[0]
                    root.status = parts[1]
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: fetchProcess.running = true
    }

    Row {
        id: row
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
            text: root.status === "Charging" ? "󰂄" : "󰁹"
            color: root.status === "Charging" ? "#9ece6a" : (parseInt(root.capacity) < 20 ? "#f7768e" : "#9ece6a")
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.capacity + "%"
            color: "#c0caf5"
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
