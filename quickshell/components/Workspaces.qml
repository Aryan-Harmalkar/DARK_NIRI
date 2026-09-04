import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: workspacesRoot
    implicitHeight: 30
    implicitWidth: Math.max(row.implicitWidth, 30)

    property var workspacesList: []

    Process {
        id: fetchWorkspaces
        command: ["niri", "msg", "-j", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text)
                    workspacesList = parsed
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: {
            fetchWorkspaces.running = true
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
