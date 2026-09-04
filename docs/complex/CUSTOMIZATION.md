# 🎨 Customization & Widget Development Guide

This guide explains how to add new widgets, custom scripts, and personalized themes.

---

## 1. Adding a New QuickShell Widget

1. Create a new QML file in `quickshell/components/MyWidget.qml`:
   ```qml
   import QtQuick
   import Quickshell
   import Quickshell.Io

   Item {
       id: root
       implicitWidth: textLabel.implicitWidth
       implicitHeight: 30

       Text {
           id: textLabel
           text: "Custom Widget"
           color: "#c0caf5"
           font.pixelSize: 13
       }
   }
   ```
2. Import and instantiate the component in `quickshell/shell.qml`:
   ```qml
   // Inside the left, center, or right RowLayout in shell.qml:
   Components.MyWidget {}
   ```
3. Reload QuickShell: Click the reload button in the Settings panel or run `killall qs; qs -d -p $HOME/DARK_NIRI/quickshell/shell.qml &`.
