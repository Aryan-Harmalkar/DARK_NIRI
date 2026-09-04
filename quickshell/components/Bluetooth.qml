import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 30

    property bool isOff: false

    Process {
        id: fetchProcess
        command: ["sh", "-c", "rfkill list bluetooth | grep 'Soft blocked: yes'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.isOff = (text.trim() !== "")
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
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
            text: root.isOff ? "󰂲" : "󰂯"
            color: root.isOff ? "#f7768e" : "#7dcfff"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["rfkill", "toggle", "bluetooth"])
            fetchProcess.running = true
        }
    }
}
