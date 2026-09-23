import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: clockRoot
    implicitWidth: clockBadge.width
    implicitHeight: 28

    // Hover state management with grace timer
    property bool isHovered: false

    Timer {
        id: hideTimer
        interval: 350
        onTriggered: clockRoot.isHovered = false
    }

    // Telemetry and System Information
    property string tzName: "Local"
    property string tzAbbr: "UTC"
    property string tzOffset: "+00:00"
    property string sysUptime: "0m"
    property string ntpSync: "no"

    // Time & Date strings
    property string barDate: ""
    property string barTime: ""
    property string fullDateLong: ""
    property string hoursMinutes: ""
    property string secondsText: ""
    property string ampmText: ""
    property string fullTime24: ""
    property string utcTime: ""
    property int epochSeconds: 0
    property int dayProgressPct: 0
    property string yearProgressPct: "0.0%"
    property int dayOfYear: 1
    property int daysInYear: 365
    property int weekNumber: 1
    property string quarterStr: "Q1"

    // Calendar State
    property int currentYear: new Date().getFullYear()
    property int currentMonth: new Date().getMonth()
    property int currentDay: new Date().getDate()
    property int viewYear: currentYear
    property int viewMonth: currentMonth
    property var calendarDays: []

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayLabels: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11
            viewYear--
        } else {
            viewMonth--
        }
        rebuildCalendar()
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0
            viewYear++
        } else {
            viewMonth++
        }
        rebuildCalendar()
    }

    function resetToToday() {
        let now = new Date()
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
        rebuildCalendar()
    }

    function rebuildCalendar() {
        let cells = []
        let firstDay = new Date(viewYear, viewMonth, 1)
        // Monday = 0: (getDay() + 6) % 7
        let startOffset = (firstDay.getDay() + 6) % 7
        let daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        let daysInPrevMonth = new Date(viewYear, viewMonth, 0).getDate()

        let now = new Date()
        let isCurrentMonthViewing = (viewYear === now.getFullYear() && viewMonth === now.getMonth())
        let todayDate = now.getDate()

        // 42 slots (6 full weeks) ensures stable layout dimensions
        for (let i = 0; i < 42; i++) {
            let dayNum = 0
            let inMonth = false
            let isToday = false
            let isWeekend = ((i % 7) === 5 || (i % 7) === 6)

            if (i < startOffset) {
                dayNum = daysInPrevMonth - startOffset + 1 + i
                inMonth = false
            } else if (i >= startOffset + daysInMonth) {
                dayNum = i - (startOffset + daysInMonth) + 1
                inMonth = false
            } else {
                dayNum = i - startOffset + 1
                inMonth = true
                if (isCurrentMonthViewing && dayNum === todayDate) {
                    isToday = true
                }
            }

            cells.push({
                "day": dayNum,
                "inMonth": inMonth,
                "isToday": isToday,
                "isWeekend": isWeekend
            })
        }
        clockRoot.calendarDays = cells
    }

    function updateTimeData() {
        let now = new Date()
        clockRoot.barDate = Qt.formatDateTime(now, "ddd, MMM d")
        clockRoot.barTime = Qt.formatDateTime(now, "hh:mm AP")

        clockRoot.fullDateLong = Qt.formatDateTime(now, "dddd, MMMM d, yyyy")
        clockRoot.hoursMinutes = Qt.formatDateTime(now, "hh:mm")
        clockRoot.secondsText = Qt.formatDateTime(now, "ss")
        clockRoot.ampmText = Qt.formatDateTime(now, "AP")
        clockRoot.fullTime24 = Qt.formatDateTime(now, "HH:mm:ss")
        clockRoot.epochSeconds = Math.floor(now.getTime() / 1000)

        // UTC Time calculation
        let utch = now.getUTCHours()
        let utcm = now.getUTCMinutes()
        let utcs = now.getUTCSeconds()
        clockRoot.utcTime = (utch < 10 ? "0" : "") + utch + ":" + (utcm < 10 ? "0" : "") + utcm + ":" + (utcs < 10 ? "0" : "") + utcs + " UTC"

        // Day Progress calculation
        let secPassed = (now.getHours() * 3600) + (now.getMinutes() * 60) + now.getSeconds()
        clockRoot.dayProgressPct = Math.min(100, Math.max(0, Math.round((secPassed / 86400) * 100)))

        // Day of Year and Year Progress calculation
        let start = new Date(now.getFullYear(), 0, 0)
        let diff = now - start
        let oneDay = 1000 * 60 * 60 * 24
        let doy = Math.floor(diff / oneDay)
        clockRoot.dayOfYear = doy
        let isLeap = ((now.getFullYear() % 4 === 0 && now.getFullYear() % 100 !== 0) || (now.getFullYear() % 400 === 0))
        clockRoot.daysInYear = isLeap ? 366 : 365
        clockRoot.yearProgressPct = ((doy / clockRoot.daysInYear) * 100).toFixed(1) + "%"

        // ISO Week Number
        let d = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()))
        let dayNum = d.getUTCDay() || 7
        d.setUTCDate(d.getUTCDate() + 4 - dayNum)
        let yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
        clockRoot.weekNumber = Math.ceil((((d - yearStart) / 86400000) + 1) / 7)

        // Quarter calculation
        let m = now.getMonth()
        if (m < 3) clockRoot.quarterStr = "Q1"
        else if (m < 6) clockRoot.quarterStr = "Q2"
        else if (m < 9) clockRoot.quarterStr = "Q3"
        else clockRoot.quarterStr = "Q4"
    }

    // Helper process to query system timezone, uptime, and NTP sync
    Process {
        id: clockInfoProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/clock-info.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text.trim())
                    if (d.tz_name) clockRoot.tzName = d.tz_name
                    if (d.tz_abbr) clockRoot.tzAbbr = d.tz_abbr
                    if (d.tz_offset) clockRoot.tzOffset = d.tz_offset
                    if (d.uptime) clockRoot.sysUptime = d.uptime
                    if (d.ntp) clockRoot.ntpSync = d.ntp
                } catch(e) {}
            }
        }
    }

    // 1-second interval timer for live clock ticking
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockRoot.updateTimeData()
            if (clockRoot.isHovered && !clockInfoProcess.running) {
                clockInfoProcess.running = true
            }
        }
    }

    Component.onCompleted: {
        updateTimeData()
        rebuildCalendar()
        clockInfoProcess.running = true
    }

    // Top Bar Indicator Pill Badge
    Rectangle {
        id: clockBadge
        width: contentRow.implicitWidth + 20
        height: 28
        radius: 14
        color: clockRoot.isHovered ? Components.Theme.surfaceHover : Components.Theme.surface
        border.color: clockRoot.isHovered ? Components.Theme.accent : Components.Theme.border
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                id: dateText
                text: clockRoot.barDate
                color: clockRoot.isHovered ? Components.Theme.fg : Components.Theme.fgMuted
                font.pixelSize: 12
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Rectangle {
                width: 3
                height: 3
                radius: 1.5
                color: Components.Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: timeText
                text: clockRoot.barTime
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
                clockRoot.isHovered = true
                clockRoot.updateTimeData()
                clockInfoProcess.running = true
            }
            onExited: hideTimer.start()
        }
    }

    // Modern Bento Hover Detail Popup Window
    PopupWindow {
        id: hoverPopup
        anchor.window: barWindow
        anchor.rect.x: Math.max(12, Math.min(barWindow.width - 576 - 12, Math.round(clockBadge.mapToItem(null, 0, 0).x - 140)))
        anchor.rect.y: Math.round(barWindow.height + 6)
        anchor.rect.width: 576
        anchor.rect.height: 1

        implicitWidth: 576
        implicitHeight: popupCard.implicitHeight
        visible: clockRoot.isHovered
        color: "transparent"

        MouseArea {
            id: popupMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                hideTimer.stop()
                clockRoot.isHovered = true
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

                // Frosted glass top highlight line
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    height: 1
                    color: "#25ffffff"
                }

                Row {
                    id: cardContent
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    spacing: 14

                    // ==========================================
                    // LEFT COLUMN (260px): Clock Cockpit & Telemetry
                    // ==========================================
                    Column {
                        width: 260
                        spacing: 11

                        // Digital Clock Bento Card
                        Rectangle {
                            width: parent.width
                            implicitHeight: clockBox.implicitHeight + 16
                            radius: 14
                            color: Components.Theme.surfaceCard
                            border.color: Components.Theme.border
                            border.width: 1

                            Column {
                                id: clockBox
                                anchors.top: parent.top
                                anchors.topMargin: 8
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                spacing: 4

                                // Large Time Row with live seconds
                                Row {
                                    spacing: 6
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        text: clockRoot.hoursMinutes
                                        color: Components.Theme.fg
                                        font.pixelSize: 28
                                        font.bold: true
                                        font.letterSpacing: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: ":" + clockRoot.secondsText
                                        color: Components.Theme.accent
                                        font.pixelSize: 20
                                        font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        height: 18
                                        width: ampmLabel.implicitWidth + 8
                                        radius: 6
                                        color: Components.Theme.surfaceHover
                                        border.color: Components.Theme.border
                                        border.width: 1
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            id: ampmLabel
                                            text: clockRoot.ampmText
                                            color: Components.Theme.accentSecondary
                                            font.pixelSize: 10
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }
                                    }
                                }

                                // 24-Hour & UTC Row
                                Row {
                                    spacing: 8
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Row {
                                        spacing: 4
                                        Text {
                                            text: "󱑂"
                                            color: Components.Theme.fgMuted
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: clockRoot.fullTime24
                                            color: Components.Theme.fgSecondary
                                            font.pixelSize: 11
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle {
                                        width: 3
                                        height: 3
                                        radius: 1.5
                                        color: Components.Theme.border
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Row {
                                        spacing: 4
                                        Text {
                                            text: "󰥔"
                                            color: Components.Theme.fgMuted
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: clockRoot.utcTime
                                            color: Components.Theme.fgMuted
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }

                        // Full Date & Milestones Pill Row
                        Column {
                            width: parent.width
                            spacing: 5

                            Text {
                                text: clockRoot.fullDateLong
                                color: Components.Theme.fg
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Row {
                                spacing: 6

                                Rectangle {
                                    height: 18
                                    width: weekTxt.implicitWidth + 10
                                    radius: 6
                                    color: Components.Theme.surfaceCard
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Text {
                                        id: weekTxt
                                        text: "󰃭 Wk " + clockRoot.weekNumber
                                        color: Components.Theme.accentTertiary
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }

                                Rectangle {
                                    height: 18
                                    width: doyTxt.implicitWidth + 10
                                    radius: 6
                                    color: Components.Theme.surfaceCard
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Text {
                                        id: doyTxt
                                        text: "󰃮 Day " + clockRoot.dayOfYear + "/" + clockRoot.daysInYear
                                        color: Components.Theme.fgSecondary
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }

                                Rectangle {
                                    height: 18
                                    width: qTxt.implicitWidth + 10
                                    radius: 6
                                    color: Components.Theme.surfaceCard
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Text {
                                        id: qTxt
                                        text: clockRoot.quarterStr
                                        color: Components.Theme.accentSecondary
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }

                        // Temporal Progress Bars (Day & Year Gauges)
                        Column {
                            width: parent.width
                            spacing: 6

                            // Day Progress
                            Column {
                                width: parent.width
                                spacing: 2

                                Item {
                                    width: parent.width
                                    height: 14

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Day Progress"
                                        color: Components.Theme.fgMuted
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: clockRoot.dayProgressPct + "%"
                                        color: Components.Theme.accent
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Components.Theme.surfaceCard

                                    Rectangle {
                                        width: Math.round(parent.width * (clockRoot.dayProgressPct / 100))
                                        height: parent.height
                                        radius: 2
                                        color: Components.Theme.accent
                                        Behavior on width { NumberAnimation { duration: 300 } }
                                    }
                                }
                            }

                            // Year Progress
                            Column {
                                width: parent.width
                                spacing: 2

                                Item {
                                    width: parent.width
                                    height: 14

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: clockRoot.currentYear + " Elapsed"
                                        color: Components.Theme.fgMuted
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: clockRoot.yearProgressPct
                                        color: Components.Theme.accentSecondary
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Components.Theme.surfaceCard

                                    Rectangle {
                                        width: Math.round(parent.width * (clockRoot.dayOfYear / clockRoot.daysInYear))
                                        height: parent.height
                                        radius: 2
                                        color: Components.Theme.accentSecondary
                                        Behavior on width { NumberAnimation { duration: 300 } }
                                    }
                                }
                            }
                        }

                        // Timezone, Uptime & NTP Card
                        Rectangle {
                            width: parent.width
                            implicitHeight: tzCardCol.implicitHeight + 14
                            radius: 12
                            color: Components.Theme.surfaceCard
                            border.color: Components.Theme.border
                            border.width: 1

                            Column {
                                id: tzCardCol
                                anchors.top: parent.top
                                anchors.topMargin: 7
                                anchors.left: parent.left
                                anchors.leftMargin: 9
                                anchors.right: parent.right
                                anchors.rightMargin: 9
                                spacing: 6

                                // Timezone Row
                                Item {
                                    width: parent.width
                                    height: 18

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        Text {
                                            text: "󰅐"
                                            color: Components.Theme.accent
                                            font.pixelSize: 13
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: clockRoot.tzName
                                            color: Components.Theme.fg
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: 120
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 16
                                        width: tzBadgeTxt.implicitWidth + 8
                                        radius: 5
                                        color: Components.Theme.surfaceHover
                                        border.color: Components.Theme.border
                                        border.width: 1

                                        Text {
                                            id: tzBadgeTxt
                                            text: clockRoot.tzAbbr + " (" + clockRoot.tzOffset + ")"
                                            color: Components.Theme.accentTertiary
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }
                                    }
                                }

                                // Uptime & NTP Row
                                Item {
                                    width: parent.width
                                    height: 16

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4

                                        Text {
                                            text: "󰔛"
                                            color: Components.Theme.success
                                            font.pixelSize: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: clockRoot.sysUptime
                                            color: Components.Theme.fgSecondary
                                            font.pixelSize: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Row {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: clockRoot.ntpSync === "yes" ? Components.Theme.success : Components.Theme.warning
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: clockRoot.ntpSync === "yes" ? "NTP Synced" : "System Clock"
                                            color: Components.Theme.fgMuted
                                            font.pixelSize: 9
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Vertical Separator
                    Rectangle {
                        width: 1
                        height: 290
                        color: Components.Theme.border
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // ==========================================
                    // RIGHT COLUMN (268px): Interactive Monthly Calendar
                    // ==========================================
                    Column {
                        width: 268
                        spacing: 8

                        // Calendar Navigation Header
                        Item {
                            width: parent.width
                            height: 24

                            // Month & Year Title
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: clockRoot.monthNames[clockRoot.viewMonth] + " " + clockRoot.viewYear
                                color: Components.Theme.fg
                                font.pixelSize: 14
                                font.bold: true
                            }

                            // Controls (Prev, Today, Next)
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                // Previous Month
                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 6
                                    color: prevMouse.containsMouse ? Components.Theme.surfaceHover : "transparent"
                                    border.color: prevMouse.containsMouse ? Components.Theme.border : "transparent"
                                    border.width: 1

                                    Text {
                                        text: "◀"
                                        color: prevMouse.containsMouse ? Components.Theme.accent : Components.Theme.fgSecondary
                                        font.pixelSize: 10
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: prevMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: clockRoot.prevMonth()
                                    }
                                }

                                // Reset to Today
                                Rectangle {
                                    height: 24
                                    width: todayBtnTxt.implicitWidth + 12
                                    radius: 6
                                    color: todayMouse.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surfaceCard
                                    border.color: (clockRoot.viewMonth === clockRoot.currentMonth && clockRoot.viewYear === clockRoot.currentYear) ? Components.Theme.accent : Components.Theme.border
                                    border.width: 1

                                    Text {
                                        id: todayBtnTxt
                                        text: "Today"
                                        color: (clockRoot.viewMonth === clockRoot.currentMonth && clockRoot.viewYear === clockRoot.currentYear) ? Components.Theme.accent : Components.Theme.fgSecondary
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: todayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: clockRoot.resetToToday()
                                    }
                                }

                                // Next Month
                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 6
                                    color: nextMouse.containsMouse ? Components.Theme.surfaceHover : "transparent"
                                    border.color: nextMouse.containsMouse ? Components.Theme.border : "transparent"
                                    border.width: 1

                                    Text {
                                        text: "▶"
                                        color: nextMouse.containsMouse ? Components.Theme.accent : Components.Theme.fgSecondary
                                        font.pixelSize: 10
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: nextMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: clockRoot.nextMonth()
                                    }
                                }
                            }
                        }

                        // Day of Week Header Row
                        Row {
                            width: parent.width
                            spacing: 4
                            anchors.horizontalCenter: parent.horizontalCenter

                            Repeater {
                                model: clockRoot.dayLabels
                                Rectangle {
                                    width: 34
                                    height: 20
                                    color: "transparent"

                                    Text {
                                        text: modelData
                                        color: (index >= 5) ? Components.Theme.accentSecondary : Components.Theme.fgMuted
                                        font.pixelSize: 11
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }

                        // Calendar Day Grid (7 columns x 6 rows)
                        Grid {
                            columns: 7
                            spacing: 4
                            anchors.horizontalCenter: parent.horizontalCenter

                            Repeater {
                                model: clockRoot.calendarDays

                                Rectangle {
                                    width: 34
                                    height: 28
                                    radius: 7
                                    color: modelData.isToday ? Components.Theme.accent : (dayMouse.containsMouse ? Components.Theme.surfaceHover : "transparent")
                                    border.color: modelData.isToday ? Components.Theme.accentTertiary : (dayMouse.containsMouse ? Components.Theme.border : "transparent")
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        text: modelData.day
                                        color: modelData.isToday ? "#ffffff" : (modelData.inMonth ? (modelData.isWeekend ? Components.Theme.accentTertiary : Components.Theme.fg) : Components.Theme.fgMuted)
                                        opacity: modelData.inMonth ? 1.0 : 0.35
                                        font.pixelSize: 11
                                        font.bold: modelData.isToday
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: dayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }
                            }
                        }

                        // Calendar Bottom Status Row
                        Item {
                            width: parent.width
                            height: 16

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Components.Theme.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                                    color: Components.Theme.fgSecondary
                                    font.pixelSize: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Epoch: " + clockRoot.epochSeconds
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

