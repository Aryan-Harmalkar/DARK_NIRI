import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: root
    implicitWidth: batPill.width
    implicitHeight: 28

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

    Rectangle {
        id: batPill
        width: row.implicitWidth + 18
        height: 28
        radius: 14
        color: batMouse.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
        border.color: batMouse.containsMouse ? Components.Theme.accent : Components.Theme.border
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: row
            spacing: 6
            anchors.centerIn: parent
            
            Text {
                text: root.status === "Charging" ? "󰂄" : (parseInt(root.capacity) < 20 ? "󰂃" : (parseInt(root.capacity) < 50 ? "󰁽" : "󰁹"))
                color: root.status === "Charging" ? Components.Theme.success : (parseInt(root.capacity) < 20 ? Components.Theme.danger : Components.Theme.success)
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: root.capacity + "%"
                color: Components.Theme.fg
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: batMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fetchProcess.running = true
        }
    }
}
