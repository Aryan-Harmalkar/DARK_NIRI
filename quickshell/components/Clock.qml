import QtQuick
import Quickshell
import "." as Components

Item {
    id: clockRoot
    implicitWidth: clockBadge.width
    implicitHeight: 28
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            dateText.text = Qt.formatDateTime(new Date(), "ddd, MMM d")
            timeText.text = Qt.formatDateTime(new Date(), "hh:mm AP")
        }
    }

    Rectangle {
        id: clockBadge
        width: contentRow.implicitWidth + 20
        height: 28
        radius: 14
        color: Components.Theme.surface
        border.color: Components.Theme.border
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
                text: Qt.formatDateTime(new Date(), "ddd, MMM d")
                color: Components.Theme.fgMuted
                font.pixelSize: 12
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
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
                text: Qt.formatDateTime(new Date(), "hh:mm AP")
                color: Components.Theme.fg
                font.pixelSize: 13
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
