import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: pillRow.visible ? pillRow.implicitWidth : 0
    implicitHeight: 34

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

                    let icon = root.status === "Playing" ? "󰎆" : "󰏤"
                    if (root.artist !== "" && root.title !== "") {
                        root.displayText = icon + "  " + root.artist + " - " + root.title
                    } else if (root.title !== "") {
                        root.displayText = icon + "  " + root.title
                    } else {
                        root.displayText = icon + "  " + root.artist
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
            width: Math.min(textMetric.width + 28, 420)
            height: 34
            radius: 17
            color: pillMouseArea.containsMouse ? "#E624283b" : "#E61f2335"
            border.color: pillMouseArea.containsMouse ? "#7aa2f7" : "#3b4261"
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            TextMetrics {
                id: textMetric
                font.pixelSize: 14
                font.bold: true
                text: root.displayText
            }

            Text {
                text: root.displayText
                color: pillMouseArea.containsMouse ? "#bb9af7" : "#7aa2f7"
                font.pixelSize: 14
                font.bold: true
                anchors.centerIn: parent
                elide: Text.ElideRight
                width: Math.min(textMetric.width, 380)

                Behavior on color { ColorAnimation { duration: 150 } }
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
        anchor.rect.y: 55
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
                radius: 18
                color: "#F01a1b26"
                border.color: "#3b4261"
                border.width: 1

                // Album Art
                Rectangle {
                    id: albumArt
                    width: 164
                    height: 164
                    radius: 14
                    color: "#16161e"
                    clip: true
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    border.color: "#3b4261"
                    border.width: 1

                    Image {
                        id: albumArtImage
                        anchors.fill: parent
                        anchors.margins: 1
                        source: root.artUrl
                        sourceSize.width: 164
                        sourceSize.height: 164
                        fillMode: Image.PreserveAspectCrop
                        visible: root.artUrl !== ""
                    }

                    Text {
                        text: "󰎆"
                        font.pixelSize: 52
                        color: "#7aa2f7"
                        anchors.centerIn: parent
                        visible: root.artUrl === "" || albumArtImage.status !== Image.Ready
                    }
                }

                // Info & Controls Container
                Item {
                    anchors.left: albumArt.right
                    anchors.leftMargin: 20
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20

                    // Track & Artist Info
                    Column {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 6

                        Text {
                            text: root.title !== "" ? root.title : "Unknown Title"
                            color: "#c0caf5"
                            font.pixelSize: 18
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: root.artist !== "" ? root.artist : "Unknown Artist"
                            color: "#7aa2f7"
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: root.album !== "" ? "󰀥 " + root.album : ""
                            color: "#565f89"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            width: parent.width
                            visible: root.album !== ""
                        }
                    }

                    // Interactive Controls Row
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        spacing: 20

                        // Previous Track
                        Rectangle {
                            width: 38
                            height: 38
                            radius: 19
                            color: prevHover.containsMouse ? "#24283b" : "#1f2335"
                            border.color: prevHover.containsMouse ? "#7aa2f7" : "#3b4261"
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                text: "󰒮"
                                color: prevHover.containsMouse ? "#7aa2f7" : "#c0caf5"
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
                            color: playHover.containsMouse ? "#bb9af7" : "#7aa2f7"
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                text: root.status === "Playing" ? "󰏤" : "󰐊"
                                color: "#1a1b26"
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
                            color: nextHover.containsMouse ? "#24283b" : "#1f2335"
                            border.color: nextHover.containsMouse ? "#7aa2f7" : "#3b4261"
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                text: "󰒭"
                                color: nextHover.containsMouse ? "#7aa2f7" : "#c0caf5"
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
