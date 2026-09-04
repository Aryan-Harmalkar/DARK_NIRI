import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: root.recordStatus !== "idle" ? row.implicitWidth : 0
    implicitHeight: 32
    visible: root.recordStatus !== "idle"

    property string recordStatus: "idle"

    Process {
        id: statusProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/screencast.sh", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") {
                    root.recordStatus = out
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: statusProcess.running = true
    }

    Row {
        id: row
        spacing: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: root.recordStatus !== "idle"
        
        // Pause / Resume button
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: root.recordStatus === "recording" ? "#f7768e" : "#e0af68"
            
            Text {
                text: root.recordStatus === "recording" ? "󰏤" : "󰐊"
                color: "#1a1b26"
                font.pixelSize: 18
                anchors.centerIn: parent
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/screencast.sh", "pause"])
                    statusProcess.running = true
                }
            }
        }

        // Stop button
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: "#f7768e"
            
            Text {
                text: "󰓛"
                color: "#1a1b26"
                font.pixelSize: 18
                anchors.centerIn: parent
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/screencast.sh", "stop"])
                    statusProcess.running = true
                }
            }
        }
    }
}
