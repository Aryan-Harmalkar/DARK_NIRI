import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "components" as Components

ShellRoot {
    // Interactive wallpaper background window
    WallpaperWindow {}

    // Top status bar
    PanelWindow {
        id: barWindow
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        
        // Position at the top of the screen
        anchors {
            top: true
            left: true
            right: true
        }
        
        // 1.25x Bar height (55px)
        implicitHeight: 55
        
        // Bar Background (semi-transparent)
        color: "#E61a1b26"
        
        // Subtle bottom border
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#292e42"
        }

        // Left section (Workspaces/Logo/Clock/SysInfo)
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 18
            
            Process {
                id: rofiLauncher
                command: ["rofi", "-show", "drun", "-theme", Quickshell.env("HOME") + "/DARK_NIRI/rofi/config.rasi"]
            }

            Item {
                width: logoText.implicitWidth
                height: logoText.implicitHeight
                anchors.verticalCenter: parent.verticalCenter
                
                Text {
                    id: logoText
                    text: "◆"
                    color: "#7aa2f7"
                    font.bold: true
                    font.pixelSize: 20
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rofiLauncher.running = true
                }
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

        // Center section (Media)
        Components.Media {
            anchors.centerIn: parent
        }

        // Right section (Clean: Screencast when active + Battery + Settings Control Center)
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16
            
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
