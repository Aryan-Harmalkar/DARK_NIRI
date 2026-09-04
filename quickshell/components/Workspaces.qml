import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: workspacesRoot
    implicitHeight: 30
    implicitWidth: Math.max(row.implicitWidth, 30)

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

    Row {
        id: row
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter
        
        Repeater {
            model: workspacesRoot.workspacesList.length
            delegate: Rectangle {
                width: workspacesRoot.workspacesList[index].is_focused ? 30 : 10
                height: 10
                radius: 5
                color: workspacesRoot.workspacesList[index].is_focused ? "#7aa2f7" : "#414868"
                Behavior on width { NumberAnimation { duration: 200 } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                Process {
                    id: switchWorkspace
                    command: ["niri", "msg", "action", "focus-workspace", (workspacesRoot.workspacesList[index] || {}).id ? workspacesRoot.workspacesList[index].id.toString() : ""]
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        switchWorkspace.running = true
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
