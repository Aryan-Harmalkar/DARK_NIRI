import QtQuick
import Quickshell

Item {
    id: root
    width: 500
    height: 100

    property string displayText: ""

    // Outer box that is hidden when media implicitWidth is 0
    Rectangle {
        id: islandBox
        visible: media.implicitWidth > 0
        width: media.implicitWidth + 24
        height: 44

        Item {
            id: media
            implicitWidth: root.displayText !== "" ? pillRow.implicitWidth : 0
            implicitHeight: 28

            Row {
                id: pillRow
                visible: root.displayText !== ""
                Rectangle {
                    id: pillRect
                    width: Math.min(contentLayout.implicitWidth + 24, 420)
                    height: 28
                    Row {
                        id: contentLayout
                        Text {
                            text: root.displayText
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            console.log("BEFORE text set:")
            console.log("  media.implicitWidth =", media.implicitWidth)
            console.log("  islandBox.visible =", islandBox.visible)
            
            console.log("Setting root.displayText to 'Artist - Song'...")
            root.displayText = "Artist - Song"
        }
    }

    Timer {
        interval: 300
        running: true
        onTriggered: {
            console.log("AFTER text set (interval 300):")
            console.log("  root.displayText =", root.displayText)
            console.log("  contentLayout.implicitWidth =", contentLayout.implicitWidth)
            console.log("  pillRect.width =", pillRect.width)
            console.log("  pillRow.visible =", pillRow.visible)
            console.log("  pillRow.implicitWidth =", pillRow.implicitWidth)
            console.log("  media.implicitWidth =", media.implicitWidth)
            console.log("  islandBox.visible =", islandBox.visible)
        }
    }
}
