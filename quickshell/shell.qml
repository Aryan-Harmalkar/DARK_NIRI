import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "components" as Components

ShellRoot {
    // Top status bar supporting Floating, Split Islands, Normal edge-to-edge, and Compact styles
    PanelWindow {
        id: barWindow
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        
        // Position at the top of the screen
        anchors {
            top: true
            left: true
            right: true
        }
        
        // Dynamic bar height based on active barStyle
        implicitHeight: Components.Theme.barStyle === "compact" ? 42 : (Components.Theme.barStyle === "normal" ? 46 : 54)
        Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        
        // Transparent window background allows true floating dock and split island capsules
        color: "transparent"
        
        // Main Container (Unified capsule for Floating/Compact, Edge-to-Edge for Normal, Transparent canvas for Islands)
        Rectangle {
            id: floatingIsland
            anchors.fill: parent
            anchors.leftMargin: Components.Theme.barStyle === "normal" ? 0 : (Components.Theme.barStyle === "compact" ? 18 : (Components.Theme.barStyle === "islands" ? 0 : 12))
            anchors.rightMargin: Components.Theme.barStyle === "normal" ? 0 : (Components.Theme.barStyle === "compact" ? 18 : (Components.Theme.barStyle === "islands" ? 0 : 12))
            anchors.topMargin: Components.Theme.barStyle === "normal" ? 0 : (Components.Theme.barStyle === "compact" ? 3 : (Components.Theme.barStyle === "islands" ? 0 : 5))
            anchors.bottomMargin: Components.Theme.barStyle === "normal" ? 0 : (Components.Theme.barStyle === "compact" ? 3 : (Components.Theme.barStyle === "islands" ? 0 : 5))
            radius: Components.Theme.barStyle === "normal" ? 0 : (Components.Theme.barStyle === "compact" ? 16 : (Components.Theme.barStyle === "islands" ? 0 : 22))
            color: Components.Theme.barStyle === "islands" ? "transparent" : Components.Theme.bgAlpha
            border.color: Components.Theme.barStyle === "islands" || Components.Theme.barStyle === "normal" ? "transparent" : Components.Theme.border
            border.width: Components.Theme.barStyle === "islands" || Components.Theme.barStyle === "normal" ? 0 : 1

            Behavior on anchors.leftMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on anchors.rightMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 220 } }
            Behavior on border.color { ColorAnimation { duration: 220 } }

            // Bottom border line for Normal (Classic Edge-to-Edge) mode
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Components.Theme.border
                visible: Components.Theme.barStyle === "normal"
            }

            // Luminous frosted glass top highlight for Floating & Compact modes
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.right: parent.right
                anchors.rightMargin: 20
                height: 1
                color: "#28ffffff"
                visible: Components.Theme.barStyle === "floating" || Components.Theme.barStyle === "compact"
            }

            // Left Section (Launcher / Workspaces / Clock / SysInfo)
            Rectangle {
                id: leftIslandBox
                anchors.left: parent.left
                anchors.leftMargin: Components.Theme.barStyle === "islands" ? 12 : (Components.Theme.barStyle === "normal" ? 10 : 12)
                anchors.verticalCenter: parent.verticalCenter
                height: Components.Theme.barStyle === "islands" ? 44 : parent.height
                width: leftRow.implicitWidth + (Components.Theme.barStyle === "islands" ? 24 : 0)
                radius: Components.Theme.barStyle === "islands" ? 20 : 0
                color: Components.Theme.barStyle === "islands" ? Components.Theme.bgAlpha : "transparent"
                border.color: Components.Theme.barStyle === "islands" ? Components.Theme.border : "transparent"
                border.width: Components.Theme.barStyle === "islands" ? 1 : 0

                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on border.color { ColorAnimation { duration: 220 } }
                Behavior on radius { NumberAnimation { duration: 220 } }
                Behavior on height { NumberAnimation { duration: 220 } }
                Behavior on width { NumberAnimation { duration: 220 } }

                Row {
                    id: leftRow
                    anchors.centerIn: parent
                    spacing: 12

                    Process {
                        id: rofiLauncher
                        command: ["rofi", "-show", "drun", "-theme", Quickshell.env("HOME") + "/DARK_NIRI/rofi/config.rasi"]
                    }

                    // Super Modern Glowing Launcher Icon
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: launcherMouse.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
                        border.color: launcherMouse.containsMouse ? Components.Theme.accent : Components.Theme.border
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            id: logoText
                            text: "󰣆"
                            color: launcherMouse.containsMouse ? Components.Theme.accentSecondary : Components.Theme.accent
                            font.bold: true
                            font.pixelSize: 18
                            anchors.centerIn: parent

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: launcherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rofiLauncher.running = true
                        }
                    }

                    // Divider dot
                    Rectangle {
                        width: 3
                        height: 14
                        radius: 1.5
                        color: Components.Theme.border
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Components.Workspaces {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Components.Clock {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Components.SysInfo {
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Center Section (Media Player Island)
            Rectangle {
                id: centerIslandBox
                anchors.centerIn: parent
                height: Components.Theme.barStyle === "islands" ? 44 : parent.height
                width: centerMedia.implicitWidth + (Components.Theme.barStyle === "islands" ? 24 : 0)
                radius: Components.Theme.barStyle === "islands" ? 20 : 0
                color: Components.Theme.barStyle === "islands" ? Components.Theme.bgAlpha : "transparent"
                border.color: Components.Theme.barStyle === "islands" ? Components.Theme.border : "transparent"
                border.width: Components.Theme.barStyle === "islands" ? 1 : 0
                visible: Components.Theme.barStyle === "islands" ? (centerMedia.implicitWidth > 0) : true

                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on border.color { ColorAnimation { duration: 220 } }
                Behavior on radius { NumberAnimation { duration: 220 } }
                Behavior on height { NumberAnimation { duration: 220 } }
                Behavior on width { NumberAnimation { duration: 220 } }

                Components.Media {
                    id: centerMedia
                    anchors.centerIn: parent
                }
            }

            // Right Section (Screencast + Battery + Settings Hub)
            Rectangle {
                id: rightIslandBox
                anchors.right: parent.right
                anchors.rightMargin: Components.Theme.barStyle === "islands" ? 12 : (Components.Theme.barStyle === "normal" ? 10 : 12)
                anchors.verticalCenter: parent.verticalCenter
                height: Components.Theme.barStyle === "islands" ? 44 : parent.height
                width: rightRow.implicitWidth + (Components.Theme.barStyle === "islands" ? 24 : 0)
                radius: Components.Theme.barStyle === "islands" ? 20 : 0
                color: Components.Theme.barStyle === "islands" ? Components.Theme.bgAlpha : "transparent"
                border.color: Components.Theme.barStyle === "islands" ? Components.Theme.border : "transparent"
                border.width: Components.Theme.barStyle === "islands" ? 1 : 0

                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on border.color { ColorAnimation { duration: 220 } }
                Behavior on radius { NumberAnimation { duration: 220 } }
                Behavior on height { NumberAnimation { duration: 220 } }
                Behavior on width { NumberAnimation { duration: 220 } }

                Row {
                    id: rightRow
                    anchors.centerIn: parent
                    spacing: 12

                    Components.Screencast {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Components.Battery {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Components.Settings {
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
