import QtQuick
import Quickshell

Item {
    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockText.text = Qt.formatDateTime(new Date(), "ddd, MMM d • hh:mm AP")
        }
    }

    Text {
        id: clockText
        text: Qt.formatDateTime(new Date(), "ddd, MMM d • hh:mm AP")
        color: "#c0caf5"
        font.pixelSize: 16
        font.weight: Font.Medium
    }
}
