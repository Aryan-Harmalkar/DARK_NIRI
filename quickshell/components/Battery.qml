import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: root
    implicitWidth: batPill.width
    implicitHeight: 28

    // ── Primary Bar Pill Properties (Lightweight) ────────────
    property int capacity: 100
    property string status: "Full"

    // ── Detailed Telemetry Properties (Fetched On-Demand on Hover) ──
    property bool isHovered: false
    property string chargingDesc: "Full"
    property bool isPlugged: false
    property int health: 100
    property string cycles: "0"
    property string timeLabel: "Connected Since"
    property string timeInfo: "Just now"
    property string voltage: "0.0 V"
    property string powerDraw: "0.0 W"
    property string energyNow: ""
    property string energyFull: ""
    property string threshold: ""

    // ── Grace Period Timer for Smooth Hover Experience ───────
    Timer {
        id: hideTimer
        interval: 300
        onTriggered: root.isHovered = false
    }

    // ── 1. Lightweight Background Process (Pill only: 15s interval) ──
    Process {
        id: fetchProcess
        command: ["sh", "-c", "echo $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null),$(cat /sys/class/power_supply/BAT*/status 2>/dev/null)"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                let parts = out.split(",")
                if (parts.length >= 2 && parts[0] !== "") {
                    let cap = parseInt(parts[0])
                    if (!isNaN(cap)) root.capacity = cap
                    root.status = parts[1]
                }
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: fetchProcess.running = true
    }

    // ── 2. Detailed Telemetry Process (Active ONLY when Hovered) ──
    Process {
        id: detailedProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/battery-info.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(text.trim())
                    if (data.capacity !== undefined) root.capacity = data.capacity
                    if (data.status) root.status = data.status
                    if (data.charging_desc) root.chargingDesc = data.charging_desc
                    root.isPlugged = data.is_plugged === true
                    if (data.health !== undefined) root.health = data.health
                    if (data.cycles !== undefined) root.cycles = data.cycles
                    if (data.time_label) root.timeLabel = data.time_label
                    if (data.time_info) root.timeInfo = data.time_info
                    if (data.voltage) root.voltage = data.voltage
                    if (data.power_draw) root.powerDraw = data.power_draw
                    if (data.energy_now) root.energyNow = data.energy_now
                    if (data.energy_full) root.energyFull = data.energy_full
                    if (data.threshold) root.threshold = data.threshold
                } catch(e) {}
            }
        }
    }

    // Refresh detailed metrics periodically ONLY when hovered
    Timer {
        id: hoverRefreshTimer
        interval: 3000
        running: root.isHovered
        repeat: true
        onTriggered: detailedProcess.running = true
    }

    onIsHoveredChanged: {
        if (root.isHovered) {
            detailedProcess.running = true
        }
    }

    // ── Status Bar Pill ──────────────────────────────────────
    Rectangle {
        id: batPill
        width: row.implicitWidth + 18
        height: 28
        radius: 14
        color: (batMouse.containsMouse || root.isHovered) ? Components.Theme.surfaceHover : Components.Theme.surface
        border.color: (batMouse.containsMouse || root.isHovered) ? Components.Theme.accent : Components.Theme.border
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: row
            spacing: 6
            anchors.centerIn: parent

            Text {
                text: (root.status === "Charging" || root.isPlugged) ? "󰂄" : (root.capacity < 20 ? "󰂃" : (root.capacity < 50 ? "󰁽" : "󰁹"))
                color: (root.status === "Charging" || root.isPlugged) ? Components.Theme.success : (root.capacity < 20 ? Components.Theme.danger : Components.Theme.success)
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: root.capacity + "%"
                color: Components.Theme.fg
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: batMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                hideTimer.stop()
                root.isHovered = true
            }
            onExited: hideTimer.start()
            onClicked: detailedProcess.running = true
        }
    }

    // ── Interactive Hover Detail Card (Quickshell PopupWindow) ─
    PopupWindow {
        id: hoverPopup
        anchor.window: barWindow
        anchor.rect.x: Math.max(12, Math.min(barWindow.width - 340 - 12, Math.round(batPill.mapToItem(null, 0, 0).x - 135)))
        anchor.rect.y: Math.round(barWindow.height + 6)
        anchor.rect.width: 340
        anchor.rect.height: 1

        implicitWidth: 340
        implicitHeight: popupCard.implicitHeight
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

            Rectangle {
                id: popupCard
                width: parent.width
                implicitHeight: cardContent.implicitHeight + 28
                radius: 18
                color: Components.Theme.bgAlpha
                border.color: Components.Theme.border
                border.width: 1

                Column {
                    id: cardContent
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    spacing: 12

                    // 1. Header: Percentage, Icon, and Plugged Status Pill
                    Row {
                        width: parent.width
                        spacing: 10

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 12
                            color: root.isPlugged ? Qt.darker(Components.Theme.success, 3.2) : Qt.darker(Components.Theme.accent, 3.2)
                            border.color: root.isPlugged ? Components.Theme.success : Components.Theme.accent
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: (root.status === "Charging" || root.isPlugged) ? "󰂄" : (root.capacity < 20 ? "󰂃" : (root.capacity < 50 ? "󰁽" : "󰁹"))
                                color: root.isPlugged ? Components.Theme.success : Components.Theme.accent
                                font.pixelSize: 24
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Row {
                                spacing: 8
                                Text {
                                    text: root.capacity + "%"
                                    color: Components.Theme.fg
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                Rectangle {
                                    height: 20
                                    width: statusText.implicitWidth + 12
                                    radius: 10
                                    color: root.isPlugged ? Qt.darker(Components.Theme.success, 3.0) : Components.Theme.surfaceHover
                                    border.color: root.isPlugged ? Components.Theme.success : Components.Theme.border
                                    border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: statusText
                                        text: root.isPlugged ? "󰚥 AC Connected" : "󰂀 On Battery"
                                        color: root.isPlugged ? Components.Theme.success : Components.Theme.fgSecondary
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            Text {
                                text: root.chargingDesc
                                color: Components.Theme.fgMuted
                                font.pixelSize: 11
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Components.Theme.border
                    }

                    // 2. Timeline Card: Since When It Is Plugged In / Running On Battery
                    Rectangle {
                        width: parent.width
                        implicitHeight: timeRow.implicitHeight + 16
                        radius: 12
                        color: Components.Theme.surface
                        border.color: Components.Theme.border
                        border.width: 1

                        Row {
                            id: timeRow
                            anchors.centerIn: parent
                            spacing: 10
                            width: parent.width - 20

                            Text {
                                text: "󱑂"
                                color: root.isPlugged ? Components.Theme.accent : Components.Theme.warning
                                font.pixelSize: 18
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30

                                Text {
                                    text: root.timeLabel
                                    color: Components.Theme.fgMuted
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                                Text {
                                    text: root.timeInfo
                                    color: Components.Theme.fg
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }
                    }

                    // 3. Bento Grid: Health & Cycles
                    Row {
                        width: parent.width
                        spacing: 8

                        // Health Card
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 64
                            radius: 12
                            color: Components.Theme.surface
                            border.color: Components.Theme.border
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                Row {
                                    spacing: 4
                                    Text {
                                        text: "󰋄"
                                        color: Components.Theme.success
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        text: "Health"
                                        color: Components.Theme.fgMuted
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Text {
                                    text: root.health + "%"
                                    color: Components.Theme.fg
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                // Visual Health Progress Bar
                                Rectangle {
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Components.Theme.surfaceHover

                                    Rectangle {
                                        width: Math.round(parent.width * (Math.min(100, Math.max(0, root.health)) / 100))
                                        height: parent.height
                                        radius: parent.radius
                                        color: root.health > 80 ? Components.Theme.success : (root.health > 50 ? Components.Theme.warning : Components.Theme.danger)
                                    }
                                }
                            }
                        }

                        // Cycle Count Card
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 64
                            radius: 12
                            color: Components.Theme.surface
                            border.color: Components.Theme.border
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                Row {
                                    spacing: 4
                                    Text {
                                        text: "󰑐"
                                        color: Components.Theme.accentSecondary
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        text: "Cycles"
                                        color: Components.Theme.fgMuted
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Text {
                                    text: root.cycles + (root.cycles === "N/A" ? "" : " cycles")
                                    color: Components.Theme.fg
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Text {
                                    text: "Discharge count"
                                    color: Components.Theme.fgMuted
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }

                    // 4. Extra Telemetry: Voltage & Energy Capacity
                    Rectangle {
                        width: parent.width
                        implicitHeight: techGrid.implicitHeight + 12
                        radius: 12
                        color: Components.Theme.surface
                        border.color: Components.Theme.border
                        border.width: 1

                        Grid {
                            id: techGrid
                            anchors.centerIn: parent
                            width: parent.width - 16
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 10

                            Row {
                                spacing: 6
                                Text { text: "Voltage:"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                Text { text: root.voltage; color: Components.Theme.fgSecondary; font.pixelSize: 10; font.bold: true }
                            }

                            Row {
                                spacing: 6
                                Text { text: "Power:"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                Text { text: root.powerDraw; color: Components.Theme.fgSecondary; font.pixelSize: 10; font.bold: true }
                            }

                            Row {
                                visible: root.energyNow !== ""
                                spacing: 6
                                Text { text: "Energy:"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                Text { text: root.energyNow + (root.energyFull !== "" ? " / " + root.energyFull : ""); color: Components.Theme.fgSecondary; font.pixelSize: 10; font.bold: true }
                            }

                            Row {
                                visible: root.threshold !== ""
                                spacing: 6
                                Text { text: "Limit:"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                                Text { text: root.threshold + "%"; color: Components.Theme.accentTertiary; font.pixelSize: 10; font.bold: true }
                            }
                        }
                    }
                }
            }
        }
    }
}
