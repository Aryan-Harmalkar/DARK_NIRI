import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: workspacesRoot
    implicitHeight: 30
    implicitWidth: Math.max(capsuleBg.width, 30)

    property string screenName: ""
    property var allWorkspaces: []
    property var workspacesList: []

    function updateFilteredList() {
        if (!allWorkspaces || allWorkspaces.length === 0) {
            workspacesList = [];
            return;
        }
        let list = allWorkspaces;
        if (screenName && screenName !== "") {
            let filtered = list.filter(w => w.output === screenName);
            if (filtered.length > 0) {
                workspacesList = filtered.sort((a, b) => a.idx - b.idx);
                return;
            }
        }
        workspacesList = list.slice().sort((a, b) => a.idx - b.idx);
    }

    onScreenNameChanged: updateFilteredList()
    onAllWorkspacesChanged: updateFilteredList()

    // 1. One-shot & refresh fetch from Niri compositor
    Process {
        id: refreshWorkspaces
        command: ["niri", "msg", "-j", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text);
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        allWorkspaces = parsed;
                    }
                } catch(e) {}
            }
        }
    }

    // 2. Real-time event stream from Niri compositor
    Process {
        id: eventStream
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    let obj = JSON.parse(line);
                    if (obj.WorkspacesChanged && obj.WorkspacesChanged.workspaces) {
                        allWorkspaces = obj.WorkspacesChanged.workspaces;
                    } else if (obj.WorkspaceActivated) {
                        let actId = obj.WorkspaceActivated.id;
                        let isFoc = !!obj.WorkspaceActivated.focused;
                        let targetOutput = "";
                        for (let i = 0; i < allWorkspaces.length; i++) {
                            if (allWorkspaces[i].id === actId) {
                                targetOutput = allWorkspaces[i].output;
                                break;
                            }
                        }
                        allWorkspaces = allWorkspaces.map(w => {
                            let copy = Object.assign({}, w);
                            if (w.id === actId) {
                                copy.is_active = true;
                                if (isFoc) copy.is_focused = true;
                            } else if (targetOutput && copy.output === targetOutput) {
                                copy.is_active = false;
                                copy.is_focused = false;
                            } else if (isFoc) {
                                copy.is_focused = false;
                            }
                            return copy;
                        });
                        refreshWorkspaces.running = true;
                    } else if (obj.WindowFocusChanged || obj.WindowsChanged) {
                        refreshWorkspaces.running = true;
                    }
                } catch(e) {}
            }
        }
    }

    // 3. Fallback sync timer
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: refreshWorkspaces.running = true
    }

    // 4. Processes for user interaction
    Process {
        id: switchWorkspaceProc
    }

    function switchToWorkspace(output, idx) {
        switchWorkspaceProc.command = ["niri", "msg", "action", "focus-workspace", idx.toString()];
        switchWorkspaceProc.running = true;
    }

    Process {
        id: scrollWorkspacesProc
    }

    function scrollWorkspaces(direction) {
        let cmd = direction > 0 ? "focus-workspace-down" : "focus-workspace-up";
        scrollWorkspacesProc.command = ["niri", "msg", "action", cmd];
        scrollWorkspacesProc.running = true;
    }

    // Neo-Glass Capsule Container
    Rectangle {
        id: capsuleBg
        width: row.implicitWidth + 16
        height: 28
        radius: 14
        color: capsuleHoverArea.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
        border.color: capsuleHoverArea.containsMouse ? Components.Theme.accentSecondary : Components.Theme.border
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Wheel handler across entire capsule without blocking pill clicks
        MouseArea {
            id: capsuleHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            property int accumulatedDelta: 0

            onWheel: (wheel) => {
                accumulatedDelta += wheel.angleDelta.y;
                if (Math.abs(accumulatedDelta) >= 60) {
                    if (accumulatedDelta > 0) {
                        workspacesRoot.scrollWorkspaces(-1);
                    } else {
                        workspacesRoot.scrollWorkspaces(1);
                    }
                    accumulatedDelta = 0;
                }
            }
        }

        Row {
            id: row
            spacing: 6
            anchors.centerIn: parent
            z: 2
            
            Repeater {
                model: workspacesRoot.workspacesList.length
                delegate: Item {
                    id: wsDelegate
                    property var wsData: workspacesRoot.workspacesList[index]
                    property bool isCurrentActive: wsData && wsData.is_active
                    property bool isCurrentFocused: wsData && wsData.is_focused
                    property bool hasWindows: wsData && wsData.active_window_id !== null

                    implicitHeight: 28
                    implicitWidth: isCurrentActive ? 28 : (wsMouse.containsMouse ? 14 : 10)
                    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Rectangle {
                        id: wsPill
                        anchors.centerIn: parent
                        width: isCurrentActive ? 26 : (wsMouse.containsMouse ? 12 : 8)
                        height: isCurrentActive ? 12 : (wsMouse.containsMouse ? 10 : 8)
                        radius: height / 2
                        scale: wsMouse.pressed ? 0.85 : 1.0

                        color: {
                            if (isCurrentActive) {
                                return isCurrentFocused ? Components.Theme.accent : Components.Theme.accentSecondary;
                            }
                            if (wsMouse.containsMouse) {
                                return Components.Theme.accentSecondary;
                            }
                            if (hasWindows) {
                                return Components.Theme.fgMuted;
                            }
                            return Components.Theme.border;
                        }

                        border.color: {
                            if (isCurrentActive) {
                                return isCurrentFocused ? Components.Theme.accentSecondary : Components.Theme.accentTertiary;
                            }
                            if (wsMouse.containsMouse) {
                                return Components.Theme.accent;
                            }
                            return "transparent";
                        }
                        border.width: isCurrentActive || wsMouse.containsMouse ? 1 : 0

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            if (wsData && wsData.idx !== undefined) {
                                workspacesRoot.switchToWorkspace(wsData.output, wsData.idx);
                            }
                        }
                    }
                }
            }
        }
    }
}
