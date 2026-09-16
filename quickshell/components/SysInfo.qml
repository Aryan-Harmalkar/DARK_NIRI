import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: root
    implicitWidth: badgeRect.width
    implicitHeight: 30

    property string cpuName: "AMD Ryzen 7"
    property string cpuCores: "12 Cores"
    property int cpuPct: 0
    property int cpuTemp: 40
    property string cpuFan: "Auto"

    property string ramUsed: "0.0"
    property string ramTotal: "0.0"
    property int ramPct: 0

    property string netDown: "0 B/s"
    property string netUp: "0 B/s"
    property string dataDay: "0 B"
    property string dataMonth: "0 B"

    property string amdName: "AMD Radeon 740M"
    property int amdTemp: 35
    property string amdPower: "iGPU"
    property string amdFan: "Auto"

    property string nvName: "NVIDIA RTX 3050"
    property int nvTemp: 0
    property int nvUtil: 0
    property string nvPower: "0 W"
    property string nvStatus: "Sleeping"
    property string uptime: "0m"
    property string cpuPower: "0 W"
    property string totalPower: "0 W"
    property string diskName: "nvme0n1"
    property string diskRead: "0 B/s"
    property string diskWrite: "0 B/s"
    property string diskTotalRead: "0 B"
    property string diskTotalWrite: "0 B"

    Process {
        id: sysProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/sysinfo.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(text.trim())
                    root.cpuName = data.cpu_name || "AMD Ryzen 7"
                    root.cpuCores = data.cpu_cores || "12 Cores"
                    root.cpuPct = data.cpu_pct || 0
                    root.cpuTemp = data.cpu_temp || 40
                    root.cpuFan = data.cpu_fan || "Auto"
                    root.cpuPower = data.cpu_power || "0 W"

                    root.ramUsed = data.ram_used || "0.0"
                    root.ramTotal = data.ram_total || "0.0"
                    root.ramPct = data.ram_pct || 0

                    root.netDown = data.net_down || "0 B/s"
                    root.netUp = data.net_up || "0 B/s"
                    root.dataDay = data.data_day || "0 B"
                    root.dataMonth = data.data_month || "0 B"

                    root.amdName = data.amd_name || "AMD Radeon 740M"
                    root.amdTemp = data.amd_temp || 35
                    root.amdPower = data.amd_power || "iGPU"
                    root.amdFan = data.amd_fan || "Auto"

                    root.nvName = data.nv_name || "NVIDIA RTX 3050"
                    root.nvTemp = data.nv_temp || 0
                    root.nvUtil = data.nv_util || 0
                    root.nvPower = data.nv_power || "0 W"
                    root.nvStatus = data.nv_status || "Sleeping"

                    root.uptime = data.uptime || "0m"
                    root.totalPower = data.total_power || "0 W"
                    root.diskName = data.disk_name || "nvme0n1"
                    root.diskRead = data.disk_read || "0 B/s"
                    root.diskWrite = data.disk_write || "0 B/s"
                    root.diskTotalRead = data.disk_total_read || "0 B"
                    root.diskTotalWrite = data.disk_total_write || "0 B"
                } catch(e) {}
            }
        }
    }

    // High efficiency: Timer ONLY runs while hovering! Zero background RAM/CPU usage when idle!
    Timer {
        interval: 1000
        running: hoverArea.containsMouse
        repeat: true
        onTriggered: sysProcess.running = true
    }

    // Background periodic commit timer for network data usage tracking (every 30 seconds)
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: sysProcess.running = true
    }

    // Bar Indicator Badge
    Rectangle {
        id: badgeRect
        width: contentRow.implicitWidth + 18
        height: 28
        radius: 14
        color: hoverArea.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
        border.color: hoverArea.containsMouse ? Components.Theme.accent : Components.Theme.border
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "󰍛"
                color: root.cpuPct > 75 ? Components.Theme.danger : (root.cpuPct > 45 ? Components.Theme.warning : Components.Theme.accent)
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.cpuPct + "%"
                color: Components.Theme.fg
                font.pixelSize: 13
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 1
                height: 12
                color: Components.Theme.border
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "󰘚"
                color: root.ramPct > 80 ? Components.Theme.danger : Components.Theme.success
                font.pixelSize: 15
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.ramPct + "%"
                color: Components.Theme.fg
                font.pixelSize: 13
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: sysProcess.running = true
        }
    }

    // 1.75x Scaled Detailed Hover Card Popup
    PopupWindow {
        id: hoverPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(badgeRect.mapToItem(null, 0, 0).x - 40)
        anchor.rect.y: Math.round(barWindow.height + 4)
        anchor.rect.width: 580
        anchor.rect.height: 1

        implicitWidth: 580
        implicitHeight: 516
        visible: hoverArea.containsMouse
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Components.Theme.bgAlpha
            border.color: Components.Theme.border
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header
                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 10
                        color: Components.Theme.bg
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "󰍛"
                            color: Components.Theme.accent
                            font.pixelSize: 22
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.cpuName + " (" + root.cpuCores + ")"
                            color: Components.Theme.fg
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: "Live System Telemetry & Hardware Monitor"
                            color: Components.Theme.fgMuted
                            font.pixelSize: 12
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Components.Theme.surfaceHover
                }

                // 1. CPU Section
                Column {
                    width: parent.width
                    spacing: 6

                    Item {
                        width: parent.width
                        height: 20

                        Row {
                            anchors.left: parent.left
                            spacing: 8
                            Text { text: "󰻠"; color: Components.Theme.accent; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "CPU Load"; color: Components.Theme.fg; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Row {
                            anchors.right: parent.right
                            spacing: 14
                            Text { text: "󰈐 " + root.cpuFan + (root.cpuFan !== "Auto" ? " RPM" : ""); color: Components.Theme.accent; font.pixelSize: 13; font.bold: true }
                            Text { text: root.cpuPower; color: Components.Theme.accentTertiary; font.pixelSize: 13; font.bold: true }
                            Text { text: root.cpuTemp + "°C"; color: root.cpuTemp > 70 ? Components.Theme.danger : Components.Theme.warning; font.pixelSize: 13; font.bold: true }
                            Text { text: root.cpuPct + "%"; color: Components.Theme.accent; font.pixelSize: 13; font.bold: true }
                        }
                    }

                    // Scaled CPU Bar (1.75x Height)
                    Rectangle {
                        width: parent.width
                        height: 9
                        radius: 5
                        color: Components.Theme.bg

                        Rectangle {
                            width: parent.width * (Math.min(100, Math.max(0, root.cpuPct)) / 100)
                            height: parent.height
                            radius: 5
                            color: root.cpuPct > 75 ? Components.Theme.danger : (root.cpuPct > 45 ? Components.Theme.warning : Components.Theme.accent)
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                // 2. RAM Section
                Column {
                    width: parent.width
                    spacing: 6

                    Item {
                        width: parent.width
                        height: 20

                        Row {
                            anchors.left: parent.left
                            spacing: 8
                            Text { text: "󰘚"; color: Components.Theme.success; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Memory (RAM)"; color: Components.Theme.fg; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Text {
                            anchors.right: parent.right
                            text: root.ramUsed + " / " + root.ramTotal + " GB (" + root.ramPct + "%)"
                            color: root.ramPct > 80 ? Components.Theme.danger : Components.Theme.success
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                    // Scaled RAM Bar (1.75x Height)
                    Rectangle {
                        width: parent.width
                        height: 9
                        radius: 5
                        color: Components.Theme.bg

                        Rectangle {
                            width: parent.width * (Math.min(100, Math.max(0, root.ramPct)) / 100)
                            height: parent.height
                            radius: 5
                            color: root.ramPct > 80 ? Components.Theme.danger : Components.Theme.success
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                // 3. Internet Speed & Total Data Usage Section
                Rectangle {
                    width: parent.width
                    height: 84
                    radius: 10
                    color: Components.Theme.bg
                    border.color: Components.Theme.surfaceHover
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Live Transfer Rates (Download & Upload)
                        Row {
                            width: parent.width
                            height: 24

                            Row {
                                width: (parent.width - 1) / 2
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "󰇚"; color: Components.Theme.accentTertiary; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Download:"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.netDown; color: Components.Theme.accentTertiary; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Rectangle { width: 1; height: 18; color: Components.Theme.surfaceHover; anchors.verticalCenter: parent.verticalCenter }

                            Row {
                                width: (parent.width - 1) / 2
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                Text { text: "󰕒"; color: Components.Theme.success; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Upload:"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.netUp; color: Components.Theme.success; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }

                        // Divider
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Components.Theme.bgAlt
                        }

                        // Total Data Used (Today & This Month)
                        Row {
                            width: parent.width
                            height: 24

                            Row {
                                width: (parent.width - 1) / 2
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "󰔛"; color: Components.Theme.warning; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Today:"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.dataDay; color: Components.Theme.warning; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Rectangle { width: 1; height: 18; color: Components.Theme.surfaceHover; anchors.verticalCenter: parent.verticalCenter }

                            Row {
                                width: (parent.width - 1) / 2
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                Text { text: "󰃭"; color: Components.Theme.accentSecondary; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Month:"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.dataMonth; color: Components.Theme.accentSecondary; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }

                // 4. NVMe SSD Storage I/O Section
                Rectangle {
                    width: parent.width
                    height: 84
                    radius: 10
                    color: Components.Theme.bg
                    border.color: Components.Theme.surfaceHover
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Live Disk Transfer Rates (Read & Write)
                        Row {
                            width: parent.width
                            height: 24

                            Row {
                                width: (parent.width - 1) / 2
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "󰇚"; color: Components.Theme.accent; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Disk Read:"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.diskRead; color: Components.Theme.accent; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Rectangle { width: 1; height: 18; color: Components.Theme.surfaceHover; anchors.verticalCenter: parent.verticalCenter }

                            Row {
                                width: (parent.width - 1) / 2
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                Text { text: "󰕒"; color: Components.Theme.warning; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Disk Write:"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.diskWrite; color: Components.Theme.warning; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }

                        // Divider
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Components.Theme.bgAlt
                        }

                        // Total Boot I/O (Read & Written)
                        Row {
                            width: parent.width
                            height: 24

                            Row {
                                width: (parent.width - 1) / 2
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "󰋊"; color: Components.Theme.accentTertiary; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Boot Read:"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.diskTotalRead; color: Components.Theme.accentTertiary; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Rectangle { width: 1; height: 18; color: Components.Theme.surfaceHover; anchors.verticalCenter: parent.verticalCenter }

                            Row {
                                width: (parent.width - 1) / 2
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                Text { text: "󰔛"; color: Components.Theme.accentSecondary; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Boot Written:"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.diskTotalWrite; color: Components.Theme.accentSecondary; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }

                // 5. Dual GPU Section (AMD iGPU + NVIDIA dGPU)
                Row {
                    width: parent.width
                    spacing: 12

                    // GPU 1: AMD Radeon 740M (iGPU)
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 84
                        radius: 10
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Row {
                                spacing: 6
                                Text { text: "󰢮"; color: Components.Theme.danger; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Radeon 740M (iGPU)"; color: Components.Theme.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Row {
                                spacing: 8
                                Text { text: "Temp: " + root.amdTemp + "°C"; color: Components.Theme.warning; font.pixelSize: 12; font.bold: true }
                                Text { text: "• Power: " + root.amdPower; color: Components.Theme.fgMuted; font.pixelSize: 12 }
                            }

                            Text {
                                text: "Fan Speed: " + root.amdFan + (root.amdFan !== "Auto" ? " RPM" : "");
                                color: Components.Theme.fgMuted;
                                font.pixelSize: 11
                            }
                        }
                    }

                    // GPU 2: NVIDIA GeForce RTX 3050 (dGPU)
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 84
                        radius: 10
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Row {
                                spacing: 6
                                Text { text: "󰢮"; color: "#73daca"; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "RTX 3050 Laptop (dGPU)"; color: Components.Theme.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Row {
                                spacing: 8
                                Text {
                                    text: root.nvStatus === "Active" ? ("Temp: " + root.nvTemp + "°C") : "Status: Sleeping";
                                    color: root.nvStatus === "Active" ? Components.Theme.warning : Components.Theme.fgMuted;
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Text {
                                    visible: root.nvStatus === "Active"
                                    text: "• Power: " + root.nvPower;
                                    color: Components.Theme.fgMuted;
                                    font.pixelSize: 12
                                }
                            }

                            Text {
                                text: root.nvStatus === "Active" ? ("Usage: " + root.nvUtil + "% • Dedicated Active") : "Power Save: D3 Cold Suspend";
                                color: Components.Theme.fgMuted;
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // 5. Uptime Footer
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Components.Theme.surfaceHover
                }

                Item {
                    width: parent.width
                    height: 18

                    Row {
                        anchors.left: parent.left
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "󰔚"
                            color: Components.Theme.accentTertiary
                            font.pixelSize: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Uptime"
                            color: Components.Theme.fgMuted
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.uptime
                            color: Components.Theme.accentTertiary
                            font.pixelSize: 13
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "󰠠"
                            color: Components.Theme.warning
                            font.pixelSize: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Total"
                            color: Components.Theme.fgMuted
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.totalPower
                            color: Components.Theme.warning
                            font.pixelSize: 13
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
