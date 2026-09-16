import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: root
    implicitWidth: pillRow.visible ? pillRow.implicitWidth : 0
    implicitHeight: 28

    property string status: ""
    property string artist: ""
    property string title: ""
    property string album: ""
    property string artUrl: ""
    property string displayText: ""
    property bool isHovered: false

    Process {
        id: mediaProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/media.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = text.trim()
                if (raw !== "") {
                    let parts = raw.split("|||")
                    root.status = parts[0] || ""
                    root.artist = parts[1] || ""
                    root.title = parts[2] || ""
                    root.album = parts[3] || ""
                    root.artUrl = parts[4] || ""

                    if (root.artist !== "" && root.title !== "") {
                        root.displayText = root.artist + " • " + root.title
                    } else if (root.title !== "") {
                        root.displayText = root.title
                    } else {
                        root.displayText = root.artist
                    }
                } else {
                    root.status = ""
                    root.artist = ""
                    root.title = ""
                    root.album = ""
                    root.artUrl = ""
                    root.displayText = ""
                }
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: mediaProcess.running = true
    }

    // Delay timer for smooth hover out
    Timer {
        id: hideTimer
        interval: 350
        onTriggered: root.isHovered = false
    }

    Row {
        id: pillRow
        anchors.verticalCenter: parent.verticalCenter
        visible: root.displayText !== ""

        Rectangle {
            id: pillRect
            width: Math.min(contentLayout.implicitWidth + 24, 420)
            height: 28
            radius: 14
            color: pillMouseArea.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
            border.color: pillMouseArea.containsMouse ? Components.Theme.accent : Components.Theme.border
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
                id: contentLayout
                anchors.centerIn: parent
                spacing: 8

                // Dynamic Animated Equalizer Bars
                Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.status === "Playing"

                    Rectangle {
                        width: 2
                        height: 10
                        radius: 1
                        color: Components.Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on height {
                            running: root.status === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation { to: 14; duration: 280; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 4; duration: 280; easing.type: Easing.InOutQuad }
                        }
                    }
                    Rectangle {
                        width: 2
                        height: 14
                        radius: 1
                        color: Components.Theme.accentSecondary
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on height {
                            running: root.status === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation { to: 5; duration: 380; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 16; duration: 380; easing.type: Easing.InOutQuad }
                        }
                    }
                    Rectangle {
                        width: 2
                        height: 8
                        radius: 1
                        color: Components.Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on height {
                            running: root.status === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation { to: 15; duration: 220; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 3; duration: 220; easing.type: Easing.InOutQuad }
                        }
                    }
                    Rectangle {
                        width: 2
                        height: 12
                        radius: 1
                        color: Components.Theme.accentTertiary
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on height {
                            running: root.status === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation { to: 4; duration: 340; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 13; duration: 340; easing.type: Easing.InOutQuad }
                        }
                    }
                }

                // Paused Icon
                Text {
                    visible: root.status !== "Playing"
                    text: "󰏤"
                    color: Components.Theme.fgMuted
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextMetrics {
                    id: textMetric
                    font.pixelSize: 13
                    font.bold: true
                    text: root.displayText
                }

                Text {
                    text: root.displayText
                    color: pillMouseArea.containsMouse ? Components.Theme.accent : Components.Theme.fg
                    font.pixelSize: 13
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    width: Math.min(textMetric.width, 320)

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                id: pillMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    hideTimer.stop()
                    root.isHovered = true
                }
                onExited: hideTimer.start()
                onClicked: {
                    Quickshell.execDetached(["playerctl", "--ignore-player=firefox,firefox.*", "play-pause"])
                    mediaProcess.running = true
                }
            }
        }
    }

    // 2x Sized Rich Hover Card Popup
    PopupWindow {
        id: hoverPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round((barWindow.width / 2) - 270)
        anchor.rect.y: Math.round(barWindow.height + 4)
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 200
        visible: root.isHovered && root.displayText !== ""
        color: "transparent"

        MouseArea {
            id: popupMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                hideTimer.stop()
                root.isHovered = true
            }
            onExited: hideTimer.start()

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Components.Theme.bgAlpha
                border.color: Components.Theme.border
                border.width: 1

                // Album Art
                Rectangle {
                    id: albumArt
                    width: 164
                    height: 164
                    radius: 14
                    color: Components.Theme.surface
                    clip: true
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    border.color: Components.Theme.border
                    border.width: 1

                    Image {
                        anchors.fill: parent
                        source: root.artUrl !== "" ? root.artUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: root.artUrl !== ""
                    }

                    Text {
                        visible: root.artUrl === ""
                        text: "󰎆"
                        color: Components.Theme.accent
                        font.pixelSize: 64
                        anchors.centerIn: parent
                    }
                }

                // Media Info and Player Controls Column
                Column {
                    anchors.left: albumArt.right
                    anchors.leftMargin: 20
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    // Status Pill
                    Row {
                        spacing: 8
                        Rectangle {
                            height: 22
                            width: statusText.implicitWidth + 16
                            radius: 11
                            color: root.status === "Playing" ? Components.Theme.surfaceHover : Components.Theme.surface
                            border.color: root.status === "Playing" ? Components.Theme.accent : Components.Theme.border
                            border.width: 1

                            Text {
                                id: statusText
                                text: root.status === "Playing" ? "PLAYING" : "PAUSED"
                                color: root.status === "Playing" ? Components.Theme.accent : Components.Theme.fgMuted
                                font.pixelSize: 10
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                    }

                    // Title
                    Text {
                        text: root.title !== "" ? root.title : "Unknown Title"
                        color: Components.Theme.fg
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    // Artist
                    Text {
                        text: root.artist !== "" ? root.artist : "Unknown Artist"
                        color: Components.Theme.accent
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    // Album
                    Text {
                        text: root.album !== "" ? root.album : ""
                        color: Components.Theme.fgMuted
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width
                        visible: root.album !== ""
                    }

                    Item { width: 1; height: 4 }

                    // Controls Row
                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Previous Track
                        Rectangle {
                            width: 38
                            height: 38
                            radius: 19
                            color: prevHover.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
                            border.color: prevHover.containsMouse ? Components.Theme.accent : Components.Theme.border
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                text: "󰒮"
                                color: prevHover.containsMouse ? Components.Theme.accent : Components.Theme.fg
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: prevHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["playerctl", "--ignore-player=firefox,firefox.*", "previous"])
                                    mediaProcess.running = true
                                }
                            }
                        }

                        // Play / Pause Main Button
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 22
                            color: playHover.containsMouse ? Components.Theme.accentSecondary : Components.Theme.accent
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                text: root.status === "Playing" ? "󰏤" : "󰐊"
                                color: Components.Theme.bg
                                font.pixelSize: 22
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: playHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["playerctl", "--ignore-player=firefox,firefox.*", "play-pause"])
                                    mediaProcess.running = true
                                }
                            }
                        }

                        // Next Track
                        Rectangle {
                            width: 38
                            height: 38
                            radius: 19
                            color: nextHover.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
                            border.color: nextHover.containsMouse ? Components.Theme.accent : Components.Theme.border
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                text: "󰒭"
                                color: nextHover.containsMouse ? Components.Theme.accent : Components.Theme.fg
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: nextHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["playerctl", "--ignore-player=firefox,firefox.*", "next"])
                                    mediaProcess.running = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
