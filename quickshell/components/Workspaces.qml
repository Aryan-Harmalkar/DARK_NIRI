import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: workspacesRoot
    implicitHeight: 30
    implicitWidth: Math.max(capsuleBg.width, 30)

    property var workspacesList: []

    // 1. Initial one-shot fetch on load
    Process {
        id: initWorkspaces
        command: ["niri", "msg", "-j", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text)
                    workspacesList = parsed.sort((a, b) => a.idx - b.idx)
                } catch(e) {}
            }
        }
    }

    // 2. Real-time zero-overhead event stream from Niri compositor
    Process {
        id: eventStream
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    let obj = JSON.parse(line)
                    if (obj.WorkspacesChanged && obj.WorkspacesChanged.workspaces) {
                        workspacesList = obj.WorkspacesChanged.workspaces.sort((a, b) => a.idx - b.idx)
                    }
                } catch(e) {}
            }
        }
    }

    // Neo-Glass Capsule Container
    Rectangle {
        id: capsuleBg
        width: row.implicitWidth + 16
        height: 28
        radius: 14
        color: Components.Theme.surface
        border.color: Components.Theme.border
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: row
            spacing: 8
            anchors.centerIn: parent
            
            Repeater {
                model: workspacesRoot.workspacesList.length
                delegate: Rectangle {
                    id: wsPill
                    property bool isFocused: workspacesRoot.workspacesList[index] && workspacesRoot.workspacesList[index].is_focused

                    width: isFocused ? 28 : 8
                    height: isFocused ? 12 : 8
                    radius: 6
                    color: isFocused ? Components.Theme.accent : (wsMouse.containsMouse ? Components.Theme.accentSecondary : Components.Theme.border)
                    border.color: isFocused ? Components.Theme.accentSecondary : "transparent"
                    border.width: isFocused ? 1 : 0
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 180 } }
                    
                    Process {
                        id: switchWorkspace
                        command: ["niri", "msg", "action", "focus-workspace", (workspacesRoot.workspacesList[index] || {}).id ? workspacesRoot.workspacesList[index].id.toString() : ""]
                    }
                    
                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: switchWorkspace.running = true
                    }
                }
            }
        }
    }

    Process {
        id: scrollUpProcess
        command: ["niri", "msg", "action", "focus-workspace-down"]
    }
    
    Process {
        id: scrollDownProcess
        command: ["niri", "msg", "action", "focus-workspace-up"]
    }

    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                scrollUpProcess.running = true
            } else {
                scrollDownProcess.running = true
            }
        }
    }
}
