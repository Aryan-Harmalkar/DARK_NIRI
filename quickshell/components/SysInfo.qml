import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: root
    implicitWidth: badgeRect.width
    implicitHeight: 30

    // Primary Telemetry Properties
    property string cpuName: "AMD Ryzen 7"
    property string cpuCores: "12 Cores"
    property int cpuPct: 0
    property int cpuTemp: 40
    property string cpuFan: "Auto"
    property string cpuPower: "0 W"

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
    property string totalPower: "0 W"

    property string diskName: "nvme0n1"
    property string diskRead: "0 B/s"
    property string diskWrite: "0 B/s"
    property string diskTotalRead: "0 B"
    property string diskTotalWrite: "0 B"

    // Section Inspector Details State (cpu, ram, disk, net, gpu)
    property string activeSection: "cpu"
    property var detailsData: ({})

    // Hover state with grace period timer
    property bool isHovered: false

    Timer {
        id: hideTimer
        interval: 350
        onTriggered: root.isHovered = false
    }

    // 1. Primary Hardware Telemetry Process
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

    // 2. Deep Inspector Process (runs ONLY on hover)
    Process {
        id: detailsProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/sysinfo-details.sh", root.activeSection]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text.trim())
                    root.detailsData = d
                } catch(e) {}
            }
        }
    }

    onActiveSectionChanged: {
        if (root.isHovered && !detailsProcess.running) {
            detailsProcess.running = true
        }
    }

    // One-time initial read at startup for bar badge
    Component.onCompleted: sysProcess.running = true

    // High efficiency: 1s Live Timer ONLY runs while hovering
    Timer {
        interval: 1000
        running: root.isHovered
        repeat: true
        onTriggered: {
            sysProcess.running = true
            if (!detailsProcess.running) {
                detailsProcess.running = true
            }
        }
    }

    // Top Bar Indicator Pill Badge
    Rectangle {
        id: badgeRect
        width: contentRow.implicitWidth + 20
        height: 28
        radius: 14
        color: root.isHovered ? Components.Theme.surfaceHover : Components.Theme.surface
        border.color: root.isHovered ? Components.Theme.accent : Components.Theme.border
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
                font.pixelSize: 15
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
                font.pixelSize: 14
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
            onEntered: {
                hideTimer.stop()
                root.isHovered = true
                sysProcess.running = true
                detailsProcess.running = true
            }
            onExited: hideTimer.start()
        }
    }

    // Modern Bento-Grid Hardware Cockpit & Section Inspector Popup Window
    PopupWindow {
        id: hoverPopup
        anchor.window: barWindow
        anchor.rect.x: Math.max(12, Math.min(barWindow.width - 940 - 12, Math.round(badgeRect.mapToItem(null, 0, 0).x - 120)))
        anchor.rect.y: Math.round(barWindow.height + 6)
        anchor.rect.width: 940
        anchor.rect.height: 1

        implicitWidth: 940
        implicitHeight: 486
        visible: root.isHovered
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

            // Main Glass Backdrop Container
            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Components.Theme.bgAlpha
                border.color: Components.Theme.border
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    // ==========================================
                    // LEFT COLUMN (540px): Hardware Bento Cards
                    // ==========================================
                    Column {
                        width: 540
                        height: parent.height
                        spacing: 10

                        // 1. Header: CPU Model, Architecture & Live Pulse Tag
                        Item {
                            width: parent.width
                            height: 40

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 10
                                    color: Components.Theme.surface
                                    border.color: Components.Theme.accent
                                    border.width: 1
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
                                    spacing: 3

                                    Row {
                                        spacing: 8
                                        Text {
                                            text: root.cpuName
                                            color: Components.Theme.fg
                                            font.pixelSize: 15
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            height: 18
                                            width: coreText.implicitWidth + 10
                                            radius: 5
                                            color: Components.Theme.surface
                                            border.color: Components.Theme.border
                                            border.width: 1
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                id: coreText
                                                anchors.centerIn: parent
                                                text: root.cpuCores
                                                color: Components.Theme.accentSecondary
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Zen 4 Architecture • Live Hardware Telemetry"
                                        color: Components.Theme.fgMuted
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Right: Live Status Capsule
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 24
                                width: liveRow.implicitWidth + 14
                                radius: 12
                                color: Components.Theme.surface
                                border.color: Components.Theme.success
                                border.width: 1

                                Row {
                                    id: liveRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Components.Theme.success
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "LIVE 1s"
                                        color: Components.Theme.success
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        // 2. Bento Grid: CPU & RAM Cards
                        Row {
                            width: parent.width
                            spacing: 12

                            // Bento Card: CPU
                            Rectangle {
                                width: (parent.width - 12) / 2
                                height: 98
                                radius: 12
                                color: (root.activeSection === "cpu" || cpuMouse.containsMouse) ? Components.Theme.surfaceHover : Components.Theme.surfaceCard
                                border.color: root.activeSection === "cpu" ? Components.Theme.accent : (cpuMouse.containsMouse ? Components.Theme.borderActive : Components.Theme.border)
                                border.width: root.activeSection === "cpu" ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: cpuMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.activeSection = "cpu"
                                    onClicked: root.activeSection = "cpu"
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Item {
                                        width: parent.width
                                        height: 18

                                        Row {
                                            anchors.left: parent.left
                                            spacing: 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text { text: "󰻠"; color: Components.Theme.accent; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: "CPU LOAD"; color: Components.Theme.fgSecondary; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            Text { visible: root.activeSection === "cpu"; text: "●"; color: Components.Theme.accent; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter }
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            text: root.cpuPct + "%"
                                            color: root.cpuPct > 75 ? Components.Theme.danger : (root.cpuPct > 45 ? Components.Theme.warning : Components.Theme.accent)
                                            font.pixelSize: 16
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 6
                                        radius: 3
                                        color: Components.Theme.bg

                                        Rectangle {
                                            width: parent.width * (Math.min(100, Math.max(0, root.cpuPct)) / 100)
                                            height: parent.height
                                            radius: 3
                                            color: root.cpuPct > 75 ? Components.Theme.danger : (root.cpuPct > 45 ? Components.Theme.warning : Components.Theme.accent)
                                            Behavior on width { NumberAnimation { duration: 150 } }
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 6

                                        Rectangle {
                                            height: 22
                                            width: (parent.width - 12) / 3
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰔏 " + root.cpuTemp + "°C"
                                                color: root.cpuTemp > 75 ? Components.Theme.danger : (root.cpuTemp > 55 ? Components.Theme.warning : Components.Theme.fgSecondary)
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }

                                        Rectangle {
                                            height: 22
                                            width: (parent.width - 12) / 3
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󱐌 " + root.cpuPower
                                                color: Components.Theme.accentTertiary
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }

                                        Rectangle {
                                            height: 22
                                            width: (parent.width - 12) / 3
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰈐 " + root.cpuFan + (root.cpuFan !== "Auto" ? " RPM" : "")
                                                color: Components.Theme.fgSecondary
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }

                            // Bento Card: RAM
                            Rectangle {
                                width: (parent.width - 12) / 2
                                height: 98
                                radius: 12
                                color: (root.activeSection === "ram" || ramMouse.containsMouse) ? Components.Theme.surfaceHover : Components.Theme.surfaceCard
                                border.color: root.activeSection === "ram" ? Components.Theme.success : (ramMouse.containsMouse ? Components.Theme.borderActive : Components.Theme.border)
                                border.width: root.activeSection === "ram" ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: ramMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.activeSection = "ram"
                                    onClicked: root.activeSection = "ram"
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Item {
                                        width: parent.width
                                        height: 18

                                        Row {
                                            anchors.left: parent.left
                                            spacing: 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text { text: "󰘚"; color: Components.Theme.success; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: "MEMORY (RAM)"; color: Components.Theme.fgSecondary; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            Text { visible: root.activeSection === "ram"; text: "●"; color: Components.Theme.success; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter }
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            text: root.ramPct + "%"
                                            color: root.ramPct > 80 ? Components.Theme.danger : Components.Theme.success
                                            font.pixelSize: 16
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 6
                                        radius: 3
                                        color: Components.Theme.bg

                                        Rectangle {
                                            width: parent.width * (Math.min(100, Math.max(0, root.ramPct)) / 100)
                                            height: parent.height
                                            radius: 3
                                            color: root.ramPct > 80 ? Components.Theme.danger : Components.Theme.success
                                            Behavior on width { NumberAnimation { duration: 150 } }
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 6

                                        Rectangle {
                                            height: 22
                                            width: (parent.width - 6) * 0.60
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰘚 " + root.ramUsed + " / " + root.ramTotal + " GB"
                                                color: root.ramPct > 80 ? Components.Theme.danger : Components.Theme.fgSecondary
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }

                                        Rectangle {
                                            height: 22
                                            width: (parent.width - 6) * 0.40
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: (parseFloat(root.ramTotal) > 0 ? (parseFloat(root.ramTotal) - parseFloat(root.ramUsed)).toFixed(1) + " GB Free" : "Active")
                                                color: Components.Theme.success
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Bento Grid: Network Traffic & NVMe Storage I/O
                        Row {
                            width: parent.width
                            spacing: 12

                            // Bento Card: Network
                            Rectangle {
                                width: (parent.width - 12) / 2
                                height: 108
                                radius: 12
                                color: (root.activeSection === "net" || netMouse.containsMouse) ? Components.Theme.surfaceHover : Components.Theme.surfaceCard
                                border.color: root.activeSection === "net" ? Components.Theme.accentTertiary : (netMouse.containsMouse ? Components.Theme.borderActive : Components.Theme.border)
                                border.width: root.activeSection === "net" ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: netMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.activeSection = "net"
                                    onClicked: root.activeSection = "net"
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Row {
                                        spacing: 6
                                        Text { text: "󰖩"; color: Components.Theme.accentTertiary; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: "NETWORK TRAFFIC"; color: Components.Theme.fgSecondary; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        Text { visible: root.activeSection === "net"; text: "●"; color: Components.Theme.accentTertiary; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 6

                                        Rectangle {
                                            height: 26
                                            width: (parent.width - 6) / 2
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "󰇚"; color: Components.Theme.accentTertiary; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: root.netDown; color: Components.Theme.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }
                                        }

                                        Rectangle {
                                            height: 26
                                            width: (parent.width - 6) / 2
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "󰕒"; color: Components.Theme.success; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: root.netUp; color: Components.Theme.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 22
                                        radius: 6
                                        color: Components.Theme.bg
                                        border.color: Components.Theme.border
                                        border.width: 1

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 8

                                            Row {
                                                spacing: 4
                                                Text { text: "󰔛"; color: Components.Theme.warning; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: "Today: " + root.dataDay; color: Components.Theme.warning; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }

                                            Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }

                                            Row {
                                                spacing: 4
                                                Text { text: "󰃭"; color: Components.Theme.accentSecondary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: "Month: " + root.dataMonth; color: Components.Theme.accentSecondary; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }
                                        }
                                    }
                                }
                            }

                            // Bento Card: NVMe Storage I/O
                            Rectangle {
                                width: (parent.width - 12) / 2
                                height: 108
                                radius: 12
                                color: (root.activeSection === "disk" || diskMouse.containsMouse) ? Components.Theme.surfaceHover : Components.Theme.surfaceCard
                                border.color: root.activeSection === "disk" ? Components.Theme.warning : (diskMouse.containsMouse ? Components.Theme.borderActive : Components.Theme.border)
                                border.width: root.activeSection === "disk" ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: diskMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.activeSection = "disk"
                                    onClicked: root.activeSection = "disk"
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Item {
                                        width: parent.width
                                        height: 18

                                        Row {
                                            anchors.left: parent.left
                                            spacing: 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text { text: "󰋊"; color: Components.Theme.warning; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: "NVMe STORAGE"; color: Components.Theme.fgSecondary; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            Text { visible: root.activeSection === "disk"; text: "●"; color: Components.Theme.warning; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter }
                                        }

                                        Rectangle {
                                            anchors.right: parent.right
                                            height: 18
                                            width: driveNameText.implicitWidth + 8
                                            radius: 4
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                id: driveNameText
                                                anchors.centerIn: parent
                                                text: root.diskName
                                                color: Components.Theme.fgMuted
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 6

                                        Rectangle {
                                            height: 26
                                            width: (parent.width - 6) / 2
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "󰇚"; color: Components.Theme.accent; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: root.diskRead; color: Components.Theme.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }
                                        }

                                        Rectangle {
                                            height: 26
                                            width: (parent.width - 6) / 2
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "󰕒"; color: Components.Theme.warning; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: root.diskWrite; color: Components.Theme.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 22
                                        radius: 6
                                        color: Components.Theme.bg
                                        border.color: Components.Theme.border
                                        border.width: 1

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 8

                                            Row {
                                                spacing: 4
                                                Text { text: "󰋊"; color: Components.Theme.accentTertiary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: "Boot R: " + root.diskTotalRead; color: Components.Theme.accentTertiary; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }

                                            Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }

                                            Row {
                                                spacing: 4
                                                Text { text: "󰔛"; color: Components.Theme.accentSecondary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: "Boot W: " + root.diskTotalWrite; color: Components.Theme.accentSecondary; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 4. Bento Grid: Dual Graphics Accelerators
                        Row {
                            width: parent.width
                            spacing: 12

                            // Bento Card: AMD Radeon 740M (iGPU)
                            Rectangle {
                                width: (parent.width - 12) / 2
                                height: 88
                                radius: 12
                                color: (root.activeSection === "gpu" || amdMouse.containsMouse) ? Components.Theme.surfaceHover : Components.Theme.surfaceCard
                                border.color: root.activeSection === "gpu" ? Components.Theme.accentSecondary : (amdMouse.containsMouse ? Components.Theme.borderActive : Components.Theme.border)
                                border.width: root.activeSection === "gpu" ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: amdMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.activeSection = "gpu"
                                    onClicked: root.activeSection = "gpu"
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Item {
                                        width: parent.width
                                        height: 18

                                        Row {
                                            anchors.left: parent.left
                                            spacing: 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text { text: "󰢮"; color: Components.Theme.accentSecondary; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: "Radeon 740M"; color: Components.Theme.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        }

                                        Rectangle {
                                            anchors.right: parent.right
                                            height: 18
                                            width: 42
                                            radius: 4
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "iGPU"
                                                color: Components.Theme.accentSecondary
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 6

                                        Rectangle {
                                            height: 24
                                            width: (parent.width - 12) / 3
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰔏 " + root.amdTemp + "°C"
                                                color: Components.Theme.warning
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }

                                        Rectangle {
                                            height: 24
                                            width: (parent.width - 12) / 3
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󱐌 " + root.amdPower
                                                color: Components.Theme.accentTertiary
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }

                                        Rectangle {
                                            height: 24
                                            width: (parent.width - 12) / 3
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰈐 " + (root.amdFan !== "Auto" && root.amdFan !== "0" ? root.amdFan + " RPM" : "Silent")
                                                color: Components.Theme.fgMuted
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }

                            // Bento Card: NVIDIA GeForce RTX 3050 (dGPU)
                            Rectangle {
                                width: (parent.width - 12) / 2
                                height: 88
                                radius: 12
                                color: (root.activeSection === "gpu" || nvMouse.containsMouse) ? Components.Theme.surfaceHover : Components.Theme.surfaceCard
                                border.color: root.activeSection === "gpu" ? "#73daca" : (nvMouse.containsMouse ? Components.Theme.borderActive : Components.Theme.border)
                                border.width: root.activeSection === "gpu" ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: nvMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.activeSection = "gpu"
                                    onClicked: root.activeSection = "gpu"
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Item {
                                        width: parent.width
                                        height: 18

                                        Row {
                                            anchors.left: parent.left
                                            spacing: 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text { text: "󰢮"; color: "#73daca"; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: "RTX 3050 Laptop"; color: Components.Theme.fg; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        }

                                        Rectangle {
                                            anchors.right: parent.right
                                            height: 18
                                            width: nvStatusText.implicitWidth + 10
                                            radius: 4
                                            color: Components.Theme.bg
                                            border.color: root.nvStatus === "Active" ? Components.Theme.success : Components.Theme.border
                                            border.width: 1

                                            Text {
                                                id: nvStatusText
                                                anchors.centerIn: parent
                                                text: root.nvStatus === "Active" ? "● ACTIVE" : "󰒲 D3cold"
                                                color: root.nvStatus === "Active" ? Components.Theme.success : Components.Theme.fgMuted
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Item {
                                        width: parent.width
                                        height: 24

                                        Row {
                                            visible: root.nvStatus === "Active"
                                            width: parent.width
                                            spacing: 6

                                            Rectangle {
                                                height: 24
                                                width: (parent.width - 12) / 3
                                                radius: 6
                                                color: Components.Theme.bg
                                                border.color: Components.Theme.border
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰍛 " + root.nvUtil + "%"
                                                    color: Components.Theme.accent
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }

                                            Rectangle {
                                                height: 24
                                                width: (parent.width - 12) / 3
                                                radius: 6
                                                color: Components.Theme.bg
                                                border.color: Components.Theme.border
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰔏 " + root.nvTemp + "°C"
                                                    color: Components.Theme.warning
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }

                                            Rectangle {
                                                height: 24
                                                width: (parent.width - 12) / 3
                                                radius: 6
                                                color: Components.Theme.bg
                                                border.color: Components.Theme.border
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󱐌 " + root.nvPower
                                                    color: Components.Theme.fgSecondary
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: root.nvStatus !== "Active"
                                            anchors.fill: parent
                                            radius: 6
                                            color: Components.Theme.bg
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "󰒲"; color: Components.Theme.fgMuted; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: "PCIe Suspended • Zero-Wake Power Saving"; color: Components.Theme.fgMuted; font.pixelSize: 9; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 5. Divider
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Components.Theme.surface
                        }

                        // 6. Capsule Footer Bar
                        Item {
                            width: parent.width
                            height: 24

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    height: 22
                                    width: uptimeRow.implicitWidth + 12
                                    radius: 11
                                    color: Components.Theme.surface
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Row {
                                        id: uptimeRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text { text: "󰔚"; color: Components.Theme.accentTertiary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: "Uptime: " + root.uptime; color: Components.Theme.fgSecondary; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰌌 Hover cards to inspect"
                                color: Components.Theme.fgMuted
                                font.pixelSize: 10
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    height: 22
                                    width: powerRow.implicitWidth + 12
                                    radius: 11
                                    color: Components.Theme.surface
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Row {
                                        id: powerRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text { text: "󱐌"; color: Components.Theme.warning; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: "Draw: " + root.totalPower; color: Components.Theme.warning; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                            }
                        }
                    }

                    // Vertical Divider between Overview and Deep Inspector
                    Rectangle {
                        width: 1
                        height: parent.height
                        color: Components.Theme.surface
                    }

                    // ==========================================
                    // RIGHT COLUMN (354px): Section Deep Inspector
                    // ==========================================
                    Rectangle {
                        width: 354
                        height: parent.height
                        radius: 14
                        color: Components.Theme.surfaceCard
                        border.color: Components.Theme.border
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            // Inspector Header
                            Item {
                                width: parent.width
                                height: 32

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 6
                                        color: Components.Theme.bg
                                        border.color: root.activeSection === "cpu" ? Components.Theme.accent : (root.activeSection === "ram" ? Components.Theme.success : (root.activeSection === "disk" ? Components.Theme.warning : (root.activeSection === "net" ? Components.Theme.accentTertiary : Components.Theme.accentSecondary)))
                                        border.width: 1
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            anchors.centerIn: parent
                                            font.pixelSize: 14
                                            text: root.activeSection === "cpu" ? "󰻠" : (root.activeSection === "ram" ? "󰘚" : (root.activeSection === "disk" ? "󰋊" : (root.activeSection === "net" ? "󰖩" : "󰢮")))
                                            color: root.activeSection === "cpu" ? Components.Theme.accent : (root.activeSection === "ram" ? Components.Theme.success : (root.activeSection === "disk" ? Components.Theme.warning : (root.activeSection === "net" ? Components.Theme.accentTertiary : Components.Theme.accentSecondary)))
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            text: root.detailsData.title || "DEEP INSPECTOR"
                                            color: Components.Theme.fg
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                        Text {
                                            text: root.detailsData.subtitle || "Live telemetry overview"
                                            color: Components.Theme.fgMuted
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 20
                                    width: activeTagText.implicitWidth + 10
                                    radius: 4
                                    color: Components.Theme.bg
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Text {
                                        id: activeTagText
                                        anchors.centerIn: parent
                                        text: root.activeSection.toUpperCase()
                                        color: Components.Theme.accent
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }

                            // Meta Pill Row
                            Rectangle {
                                width: parent.width
                                height: 26
                                radius: 6
                                color: Components.Theme.bg
                                border.color: Components.Theme.border
                                border.width: 1

                                // CPU Meta
                                Row {
                                    visible: root.activeSection === "cpu"
                                    anchors.centerIn: parent
                                    spacing: 10
                                    Text { text: "󱐌 " + (root.detailsData.freq || "N/A"); color: Components.Theme.accentTertiary; font.pixelSize: 10; font.bold: true }
                                    Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "󰈐 " + (root.detailsData.gov || "powersave"); color: Components.Theme.fgSecondary; font.pixelSize: 10 }
                                    Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "Load: " + (root.detailsData.load || "0.0"); color: Components.Theme.warning; font.pixelSize: 10; font.bold: true }
                                }

                                // RAM Meta
                                Row {
                                    visible: root.activeSection === "ram"
                                    anchors.centerIn: parent
                                    spacing: 10
                                    Text { text: "󰘚 Free: " + (root.detailsData.avail || "N/A"); color: Components.Theme.success; font.pixelSize: 10; font.bold: true }
                                    Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "󰓡 Swap: " + (root.detailsData.swap || "None"); color: Components.Theme.warning; font.pixelSize: 10 }
                                    Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "Cache: " + (root.detailsData.cache || "0 MB"); color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                }

                                // Disk Meta
                                Row {
                                    visible: root.activeSection === "disk"
                                    anchors.centerIn: parent
                                    spacing: 10
                                    Text { text: "󰋊 " + (root.detailsData.root_disk || "nvme0n1"); color: Components.Theme.warning; font.pixelSize: 10; font.bold: true }
                                    Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "Live: " + root.diskRead + " / " + root.diskWrite; color: Components.Theme.accentTertiary; font.pixelSize: 10 }
                                }

                                // Net Meta
                                Row {
                                    visible: root.activeSection === "net"
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text { text: "󰩟 " + (root.detailsData.ip || "N/A"); color: Components.Theme.accentTertiary; font.pixelSize: 10; font.bold: true }
                                    Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "󰒍 " + (root.detailsData.gateway || "None"); color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "󱚵 " + (root.detailsData.conns || 0) + " sockets"; color: Components.Theme.success; font.pixelSize: 10 }
                                }

                                // GPU Meta
                                Row {
                                    visible: root.activeSection === "gpu"
                                    anchors.centerIn: parent
                                    spacing: 10
                                    Text { text: "󰢮 AMD VRAM: " + (root.detailsData.amd_vram || "N/A"); color: Components.Theme.accentSecondary; font.pixelSize: 10; font.bold: true }
                                    Text { text: "•"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                    Text { text: "NV: " + (root.detailsData.nv_state || "Sleeping"); color: root.detailsData.nv_state === "Active" ? Components.Theme.success : Components.Theme.fgMuted; font.pixelSize: 10 }
                                }
                            }

                            // Subheader Label
                            Text {
                                text: root.activeSection === "cpu" ? "TOP PROCESSES (BY CPU USAGE)" :
                                      (root.activeSection === "ram" ? "TOP PROCESSES (BY MEMORY CONSUMPTION)" :
                                      (root.activeSection === "disk" ? "FILESYSTEM PARTITIONS & MOUNT POINTS" :
                                      (root.activeSection === "net" ? "ACTIVE ADAPTERS & SOCKET TELEMETRY" : "GRAPHICS ACCELERATORS & VRAM POOLS")))
                                color: Components.Theme.fgMuted
                                font.pixelSize: 9
                                font.bold: true
                            }

                            // Dynamic Body Section: CPU or RAM Process List
                            Column {
                                visible: root.activeSection === "cpu" || root.activeSection === "ram"
                                width: parent.width
                                spacing: 5

                                Repeater {
                                    model: (root.detailsData && root.detailsData.items) ? root.detailsData.items : []

                                    Rectangle {
                                        width: parent.width
                                        height: 38
                                        radius: 6
                                        color: procHover.containsMouse ? Components.Theme.surfaceHover : Components.Theme.bg
                                        border.color: procHover.containsMouse ? Components.Theme.accent : Components.Theme.border
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        MouseArea {
                                            id: procHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            // PID Capsule
                                            Rectangle {
                                                height: 20
                                                width: pidLabel.implicitWidth + 8
                                                radius: 4
                                                color: Components.Theme.surface
                                                border.color: Components.Theme.border
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    id: pidLabel
                                                    anchors.centerIn: parent
                                                    text: modelData.pid
                                                    color: Components.Theme.fgMuted
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                }
                                            }

                                            // Process Name & Subtext
                                            Column {
                                                width: 140
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 2

                                                Text {
                                                    text: modelData.name
                                                    color: Components.Theme.fg
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: modelData.sub || ""
                                                    color: Components.Theme.fgMuted
                                                    font.pixelSize: 9
                                                }
                                            }

                                            // Usage Progress Bar & Metric Value
                                            Column {
                                                width: parent.width - 140 - pidLabel.implicitWidth - 24
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 3

                                                Text {
                                                    anchors.right: parent.right
                                                    text: modelData.value
                                                    color: root.activeSection === "cpu" ?
                                                           (modelData.pct > 50 ? Components.Theme.danger : Components.Theme.accent) :
                                                           Components.Theme.success
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }

                                                Rectangle {
                                                    width: parent.width
                                                    height: 4
                                                    radius: 2
                                                    color: Components.Theme.surface

                                                    Rectangle {
                                                        width: parent.width * (Math.min(100, Math.max(0, modelData.pct)) / 100)
                                                        height: parent.height
                                                        radius: 2
                                                        color: root.activeSection === "cpu" ?
                                                               (modelData.pct > 50 ? Components.Theme.danger : Components.Theme.accent) :
                                                               Components.Theme.success
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Dynamic Body Section: Storage Disk Partitions
                            Column {
                                visible: root.activeSection === "disk"
                                width: parent.width
                                spacing: 6

                                Repeater {
                                    model: (root.detailsData && root.detailsData.items) ? root.detailsData.items : []

                                    Rectangle {
                                        width: parent.width
                                        height: 54
                                        radius: 8
                                        color: Components.Theme.bg
                                        border.color: Components.Theme.border
                                        border.width: 1

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 4

                                            Item {
                                                width: parent.width
                                                height: 16

                                                Row {
                                                    anchors.left: parent.left
                                                    spacing: 6
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    Text { text: "󰋊"; color: Components.Theme.warning; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                    Text { text: modelData.mount; color: Components.Theme.fg; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                                    Text { text: "(" + modelData.name + ")"; color: Components.Theme.fgMuted; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                                                }

                                                Text {
                                                    anchors.right: parent.right
                                                    text: modelData.used + " / " + modelData.total + " (" + modelData.pct + "%)"
                                                    color: modelData.pct > 85 ? Components.Theme.danger : Components.Theme.fgSecondary
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                            Rectangle {
                                                width: parent.width
                                                height: 5
                                                radius: 2.5
                                                color: Components.Theme.surface

                                                Rectangle {
                                                    width: parent.width * (Math.min(100, Math.max(0, modelData.pct)) / 100)
                                                    height: parent.height
                                                    radius: 2.5
                                                    color: modelData.pct > 85 ? Components.Theme.danger : Components.Theme.warning
                                                }
                                            }

                                            Text {
                                                text: modelData.avail + " free on partition"
                                                color: Components.Theme.fgMuted
                                                font.pixelSize: 9
                                            }
                                        }
                                    }
                                }
                            }

                            // Dynamic Body Section: Network Adapters & Interfaces
                            Column {
                                visible: root.activeSection === "net"
                                width: parent.width
                                spacing: 6

                                // Wi-Fi / Connection Card
                                Rectangle {
                                    width: parent.width
                                    height: 54
                                    radius: 8
                                    color: Components.Theme.bg
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        Row {
                                            spacing: 6
                                            Text { text: "󰖩"; color: Components.Theme.accentTertiary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: "Active Connection: " + (root.detailsData.ssid || "Connected"); color: Components.Theme.fg; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        }

                                        Row {
                                            spacing: 12
                                            Text { text: "Primary: " + (root.detailsData.dev || "wlan0"); color: Components.Theme.fgSecondary; font.pixelSize: 10 }
                                            Text { text: "Gateway: " + (root.detailsData.gateway || "None"); color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                            Text { text: "Sockets: " + (root.detailsData.conns || 0); color: Components.Theme.success; font.pixelSize: 10; font.bold: true }
                                        }
                                    }
                                }

                                Repeater {
                                    model: (root.detailsData && root.detailsData.items) ? root.detailsData.items : []

                                    Rectangle {
                                        width: parent.width
                                        height: 38
                                        radius: 6
                                        color: Components.Theme.bg
                                        border.color: Components.Theme.border
                                        border.width: 1

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 10

                                            Rectangle {
                                                height: 20
                                                width: 50
                                                radius: 4
                                                color: Components.Theme.surface
                                                border.color: Components.Theme.border
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.name
                                                    color: Components.Theme.accentTertiary
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                }
                                            }

                                            Text {
                                                text: "IPv4: " + modelData.ip
                                                color: Components.Theme.fgSecondary
                                                font.pixelSize: 10
                                                font.bold: true
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                }
                            }

                            // Dynamic Body Section: Graphics & VRAM Details
                            Column {
                                visible: root.activeSection === "gpu"
                                width: parent.width
                                spacing: 8

                                // AMD iGPU Card
                                Rectangle {
                                    width: parent.width
                                    height: 72
                                    radius: 8
                                    color: Components.Theme.bg
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        Row {
                                            spacing: 6
                                            Text { text: "󰢮"; color: Components.Theme.accentSecondary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: "AMD Radeon 740M (Integrated APU)"; color: Components.Theme.fg; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                        }

                                        Row {
                                            width: parent.width
                                            Item {
                                                width: parent.width
                                                height: 16
                                                Text { text: "VRAM Allocation:"; color: Components.Theme.fgMuted; font.pixelSize: 10; anchors.left: parent.left }
                                                Text { text: (root.detailsData.amd_vram || "N/A"); color: Components.Theme.accentSecondary; font.pixelSize: 10; font.bold: true; anchors.right: parent.right }
                                            }
                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 5
                                            radius: 2.5
                                            color: Components.Theme.surface

                                            Rectangle {
                                                width: parent.width * (Math.min(100, Math.max(0, root.detailsData.amd_pct || 0)) / 100)
                                                height: parent.height
                                                radius: 2.5
                                                color: Components.Theme.accentSecondary
                                            }
                                        }
                                    }
                                }

                                // NVIDIA dGPU Card
                                Rectangle {
                                    width: parent.width
                                    height: 86
                                    radius: 8
                                    color: Components.Theme.bg
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        Item {
                                            width: parent.width
                                            height: 16

                                            Row {
                                                anchors.left: parent.left
                                                spacing: 6
                                                anchors.verticalCenter: parent.verticalCenter
                                                Text { text: "󰢮"; color: "#73daca"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: "NVIDIA RTX 3050 Laptop"; color: Components.Theme.fg; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                            }

                                            Text {
                                                anchors.right: parent.right
                                                text: root.detailsData.nv_state || "Sleeping"
                                                color: root.detailsData.nv_state === "Active" ? Components.Theme.success : Components.Theme.fgMuted
                                                font.pixelSize: 9
                                                font.bold: true
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        Text {
                                            text: root.detailsData.nv_state === "Active" ?
                                                  ("Driver: " + (root.detailsData.nv_drv || "NVIDIA") + " • Power: " + (root.detailsData.nv_power || "0 W")) :
                                                  "PCIe Runtime PM: D3cold Suspend State"
                                            color: Components.Theme.fgSecondary
                                            font.pixelSize: 10
                                        }

                                        Text {
                                            text: root.detailsData.nv_state === "Active" ?
                                                  ("Dedicated VRAM: " + (root.detailsData.nv_vram || "N/A")) :
                                                  "Zero-Wake: Hardware sleeps completely until heavy GPU task launched"
                                            color: Components.Theme.fgMuted
                                            font.pixelSize: 9
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
