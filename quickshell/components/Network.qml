import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 30

    property string netType: "none"
    property string netName: "Disconnected"

    function getIcon() {
        if (root.netType === "wifi") return "󰤨";
        if (root.netType === "ethernet") return "󰈀";
        if (root.netType === "usb") return "󰕄";
        if (root.netType === "cellular") return "󰀂";
        return "󰤭";
    }

    function getIconColor() {
        if (root.netType === "none" || root.netName === "Disconnected") return "#f7768e";
        if (root.netType === "ethernet" || root.netType === "usb") return "#9ece6a";
        return "#7aa2f7";
    }

    Process {
        id: fetchProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/net-tracker", "--type"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") {
                    let parts = out.split("|")
                    if (parts.length >= 2) {
                        root.netType = parts[0]
                        root.netName = parts[1]
                    }
                } else {
                    root.netType = "none"
                    root.netName = "Disconnected"
                }
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: fetchProcess.running = true
    }

    Row {
        id: row
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
            text: root.getIcon()
            color: root.getIconColor()
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.netName
            color: "#c0caf5"
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
