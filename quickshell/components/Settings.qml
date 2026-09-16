import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "." as Components

Item {
    id: root
    implicitWidth: btnRow.width
    implicitHeight: 32

    property bool isSettingsOpen: false
    property bool isGalleryOpen: false
    property bool isWifiOpen: false
    property bool isBtOpen: false
    property bool isNotifOpen: false
    property bool isThemesOpen: false

    property var themesList: []
    property string activeThemeId: "tokyo-night"
    property string activeThemeName: "Tokyo Night"

    property var wallpapers: []
    property string activeWallpaper: ""
    property int selectedTab: 0 // 0: Web Themes, 1: Wallpapers, 2: Effects & FX, 3: Performance, 4: Canvas Colors
    property var engineConfig: ({})
    property var engineStatus: ({})
    property bool isEngineRunning: false

    // Notification State
    property var notifications: []

    // Wi-Fi State
    property bool wifiEnabled: true
    property string wifiSsid: "Disconnected"
    property var wifiNetworks: []
    property string wifiSelectedSsid: ""
    property string wifiPasswordInput: ""
    property bool wifiConnecting: false

    // Bluetooth State
    property bool isBtOn: true
    property var btDevices: []
    property string btConnectedDeviceName: ""
    property bool btDiscovering: false

    // Other System States
    property bool isMicMuted: false
    property int volumeLevel: 50
    property bool isAudioMuted: false
    property int brightnessLevel: 60
    property string recordStatus: "idle"
    property string activePowerProfile: "balanced"

    readonly property var canvasColors: [
        { name: "Tokyo Night", hex: Components.Theme.bg },
        { name: "Pure Black", hex: "#0c0d14" },
        { name: "Midnight Blue", hex: "#0f141c" },
        { name: "Cyber Purple", hex: Qt.darker(Components.Theme.accentSecondary, 3.5) },
        { name: "Nord Dark", hex: Components.Theme.bgAlt },
        { name: "Catppuccin Mocha", hex: Components.Theme.bg },
        { name: "Slate Charcoal", hex: Components.Theme.bgAlt },
        { name: "Emerald Night", hex: Qt.darker(Components.Theme.success, 4.0) }
    ]

    function getFilteredWallpapers() {
        if (!root.wallpapers) return [];
        if (root.selectedTab === 0) {
            return root.wallpapers.filter(w => w.type === "theme");
        } else if (root.selectedTab === 1) {
            return root.wallpapers.filter(w => w.type === "image" || w.type === "video");
        }
        return [];
    }

    function setEffectValue(key, val) {
        // Optimistic local state update for instantaneous zero-latency UI response
        let cfg = Object.assign({}, root.engineConfig);
        if (!cfg.effects) cfg.effects = {};
        let topKeys = ["quality", "fps", "battery_saver", "pause_fullscreen", "mode", "active"];
        if (topKeys.indexOf(key) !== -1) {
            cfg[key] = val;
        } else {
            let parts = key.replace(/^effects\./, "").split(".");
            let d = cfg.effects;
            for (let i = 0; i < parts.length - 1; i++) {
                if (!d[parts[i]]) d[parts[i]] = {};
                d = d[parts[i]];
            }
            d[parts[parts.length - 1]] = val;
        }
        root.engineConfig = cfg;

        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "set-effect", key, "" + val]);
        refreshConfigTimer.running = true;
    }

    // Notifications Backend Process
    Process {
        id: notifProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/notifications.sh", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.notifications = JSON.parse(text.trim())
                } catch(e) {
                    root.notifications = []
                }
            }
        }
    }

    // Themes Backend Process
    Process {
        id: themesListProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme-manager", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let list = JSON.parse(text.trim())
                    root.themesList = list
                    for (let i = 0; i < list.length; i++) {
                        if (list[i].is_active) {
                            root.activeThemeId = list[i].id
                            root.activeThemeName = list[i].name
                            break
                        }
                    }
                } catch(e) {
                    root.themesList = []
                }
            }
        }
    }

    // Wi-Fi Backend Process
    Process {
        id: wifiListProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(text.trim())
                    root.wifiEnabled = data.enabled
                    root.wifiNetworks = data.networks || []
                    
                    let active = (data.networks || []).find(n => n.connected)
                    root.wifiSsid = active ? active.ssid : "Disconnected"
                } catch(e) {}
                root.wifiConnecting = false
            }
        }
    }

    // Wi-Fi delayed refresh timer for connection settling
    Timer {
        id: wifiRefreshTimer
        interval: 3500
        repeat: false
        onTriggered: wifiListProcess.running = true
    }

    // Bluetooth Backend Process (BlueZ)
    Process {
        id: btListProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bluetooth.sh", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(text.trim())
                    root.isBtOn = data.enabled
                    root.btDiscovering = data.discovering || false
                    root.btDevices = data.devices || []
                    
                    let conn = (data.devices || []).find(d => d.connected)
                    root.btConnectedDeviceName = conn ? conn.name : ""
                } catch(e) {}
            }
        }
    }

    // Mic Process
    Process {
        id: micProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                root.isMicMuted = (out.indexOf("[MUTED]") !== -1)
            }
        }
    }

    // Audio / Volume Process
    Process {
        id: audioProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") {
                    let parts = out.split(" ")
                    if (parts.length >= 2) {
                        let vol = parseFloat(parts[1]) * 100
                        root.volumeLevel = Math.min(100, Math.max(0, Math.round(vol)))
                        root.isAudioMuted = (out.indexOf("[MUTED]") !== -1)
                    }
                }
            }
        }
    }

    // Brightness Process
    Process {
        id: brightProcess
        command: ["sh", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") {
                    root.brightnessLevel = Math.min(100, Math.max(1, parseInt(out) || 60))
                }
            }
        }
    }

    // Recording status Process
    Process {
        id: recStatusProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/screencast.sh", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") root.recordStatus = out
            }
        }
    }

    // Power Profile Process
    Process {
        id: powerProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/powerprofile.sh", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out !== "") root.activePowerProfile = out
            }
        }
    }

    // Polling timer for live control center states
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            notifProcess.running = true
            if (root.isSettingsOpen || root.isWifiOpen || root.isBtOpen || root.isNotifOpen) {
                wifiListProcess.running = true
                btListProcess.running = true
                powerProcess.running = true
                micProcess.running = true
                audioProcess.running = true
                brightProcess.running = true
                recStatusProcess.running = true
            }
        }
    }

    // Wallpapers background processes
    Process {
        id: listProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text.trim())
                    root.wallpapers = parsed
                } catch (e) {
                    root.wallpapers = []
                }
            }
        }
    }

    Process {
        id: activeProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeWallpaper = text.trim()
            }
        }
    }

    Process {
        id: configProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "get-config"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.engineConfig = JSON.parse(text.trim())
                } catch (e) {}
            }
        }
    }

    Process {
        id: statusProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let st = JSON.parse(text.trim())
                    root.engineStatus = st
                    root.isEngineRunning = !!st.running
                } catch (e) {
                    root.isEngineRunning = false
                }
            }
        }
    }

    Timer {
        id: refreshConfigTimer
        interval: 200
        repeat: false
        onTriggered: {
            configProcess.running = true
            statusProcess.running = true
        }
    }

    // Top Bar Right Buttons: Notification Icon on Left, Settings Icon on Right
    Row {
        id: btnRow
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        // 1. Theme Button (Opens Theme Studio Modal)
        Rectangle {
            id: themeBtn
            width: 32
            height: 32
            radius: 16
            color: themeMouse.containsMouse || root.isThemesOpen ? Components.Theme.surfaceHover : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: "󰏘"
                color: root.isThemesOpen ? Components.Theme.accent : (themeMouse.containsMouse ? Components.Theme.accentSecondary : Components.Theme.fg)
                font.pixelSize: 20
                anchors.centerIn: parent

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: themeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.isThemesOpen = !root.isThemesOpen
                    if (root.isThemesOpen) {
                        root.isSettingsOpen = false
                        root.isNotifOpen = false
                        root.isGalleryOpen = false
                        root.isWifiOpen = false
                        root.isBtOpen = false
                        themesListProcess.running = true
                    }
                }
            }
        }

        // 2. Notification Icon Button
        Rectangle {
            id: notifBtn
            width: 32
            height: 32
            radius: 16
            color: notifMouse.containsMouse || root.isNotifOpen ? Components.Theme.surfaceHover : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: root.notifications.length > 0 ? "󰂚" : "󰂜"
                color: root.isNotifOpen ? Components.Theme.accent : (notifMouse.containsMouse ? Components.Theme.accentSecondary : Components.Theme.fg)
                font.pixelSize: 20
                anchors.centerIn: parent

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Unread Count Dot
            Rectangle {
                visible: root.notifications.length > 0
                width: 7
                height: 7
                radius: 3.5
                color: Components.Theme.danger
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 4
            }

            MouseArea {
                id: notifMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.isNotifOpen = !root.isNotifOpen
                    if (root.isNotifOpen) {
                        root.isSettingsOpen = false
                        root.isThemesOpen = false
                        root.isGalleryOpen = false
                        root.isWifiOpen = false
                        root.isBtOpen = false
                        notifProcess.running = true
                    }
                }
            }
        }

        // 3. Settings Control Hub Button on Bar
        Rectangle {
            id: btnRect
            width: 32
            height: 32
            radius: 16
            color: btnMouse.containsMouse || root.isSettingsOpen ? Components.Theme.surfaceHover : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: "󰒓"
                color: root.isSettingsOpen ? Components.Theme.accent : (btnMouse.containsMouse ? Components.Theme.accentSecondary : Components.Theme.fg)
                font.pixelSize: 20
                anchors.centerIn: parent

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.isSettingsOpen = !root.isSettingsOpen
                    if (root.isSettingsOpen) {
                        root.isThemesOpen = false
                        root.isNotifOpen = false
                        root.isGalleryOpen = false
                        root.isWifiOpen = false
                        root.isBtOpen = false
                        wifiListProcess.running = true
                        btListProcess.running = true
                        powerProcess.running = true
                        micProcess.running = true
                        audioProcess.running = true
                        brightProcess.running = true
                    }
                }
            }
        }
    }

    // Sleek Tokyo Night Quick Settings Control Center (Anchored Top-Right, Slide Animation)
    PopupWindow {
        id: settingsPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(barWindow.width - 540 - 20)
        anchor.rect.y: Math.round(barWindow.height + 4)
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 785
        visible: root.isSettingsOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Components.Theme.bgAlpha
            border.color: Components.Theme.border
            border.width: 1

            // Top-right slide in animation
            transform: Translate {
                x: root.isSettingsOpen ? 0 : 30
                y: root.isSettingsOpen ? 0 : -15
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            opacity: root.isSettingsOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // 1. Quick Toggle Tiles Grid (2 Columns, Full Button Color on Active!)
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 14

                    // Tile 1: Wi-Fi (Click opens Wi-Fi Manager Modal from top-right!)
                    Rectangle {
                        width: (parent.width - 14) / 2
                        height: 74
                        radius: 14
                        color: root.wifiSsid !== "Disconnected"
                               ? (wifiMouse.containsMouse ? Qt.darker(Components.Theme.accent, 2.0) : Qt.darker(Components.Theme.accent, 2.5))
                               : (wifiMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.bg)
                        border.color: root.wifiSsid !== "Disconnected" ? Components.Theme.accent : Components.Theme.surfaceHover
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Rectangle {
                                width: 48
                                height: 48
                                radius: 12
                                color: root.wifiSsid !== "Disconnected" ? Components.Theme.accent : Components.Theme.surface
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: root.wifiSsid !== "Disconnected" ? "󰤨" : "󰤭"
                                    color: root.wifiSsid !== "Disconnected" ? Components.Theme.bg : Components.Theme.fgMuted
                                    font.pixelSize: 24
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                width: parent.width - 66

                                Text {
                                    text: "Wi-Fi Networks"
                                    color: root.wifiSsid !== "Disconnected" ? "#ffffff" : Components.Theme.fg
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: root.wifiSsid !== "Disconnected" ? (root.wifiSsid + " • Manage") : "Disconnected • Scan"
                                    color: root.wifiSsid !== "Disconnected" ? Components.Theme.accentTertiary : Components.Theme.fgMuted
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            id: wifiMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                root.isWifiOpen = true
                                wifiListProcess.running = true
                            }
                        }
                    }

                    // Tile 2: Bluetooth (Click opens Bluetooth Manager Modal from top-right!)
                    Rectangle {
                        width: (parent.width - 14) / 2
                        height: 74
                        radius: 14
                        color: root.isBtOn
                               ? (btMouse.containsMouse ? Qt.darker(Components.Theme.accentTertiary, 2.5) : Qt.darker(Components.Theme.accentTertiary, 3.0))
                               : (btMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.bg)
                        border.color: root.isBtOn ? Components.Theme.accentTertiary : Components.Theme.surfaceHover
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Rectangle {
                                width: 48
                                height: 48
                                radius: 12
                                color: root.isBtOn ? Components.Theme.accentTertiary : Components.Theme.surface
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: root.isBtOn ? "󰂯" : "󰂲"
                                    color: root.isBtOn ? Components.Theme.bg : Components.Theme.fgMuted
                                    font.pixelSize: 24
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                width: parent.width - 66

                                Text {
                                    text: "Bluetooth Devices"
                                    color: root.isBtOn ? "#ffffff" : Components.Theme.fg
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: root.btConnectedDeviceName !== ""
                                          ? (root.btConnectedDeviceName + " • Connected")
                                          : (root.isBtOn ? "Enabled • Manage" : "Disabled / Off")
                                    color: root.isBtOn ? Components.Theme.accentTertiary : Components.Theme.fgMuted
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            id: btMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                root.isBtOpen = true
                                btListProcess.running = true
                            }
                        }
                    }

                    // Tile 3: Power Settings (Cycling: power saving => balanced => performance)
                    Rectangle {
                        width: (parent.width - 14) / 2
                        height: 74
                        radius: 14
                        color: root.activePowerProfile === "power-saver"
                               ? (powerTileMouse.containsMouse ? Qt.darker(Components.Theme.success, 2.5) : Qt.darker(Components.Theme.success, 3.0))
                               : (root.activePowerProfile === "performance"
                                  ? (powerTileMouse.containsMouse ? Qt.darker(Components.Theme.warning, 2.5) : Qt.darker(Components.Theme.warning, 3.0))
                                  : (powerTileMouse.containsMouse ? Qt.darker(Components.Theme.accent, 2.2) : Qt.darker(Components.Theme.accent, 3.0)))
                        border.color: root.activePowerProfile === "power-saver"
                                      ? Components.Theme.success
                                      : (root.activePowerProfile === "performance" ? Components.Theme.warning : Components.Theme.accent)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Rectangle {
                                width: 48
                                height: 48
                                radius: 12
                                color: root.activePowerProfile === "power-saver"
                                       ? Components.Theme.success
                                       : (root.activePowerProfile === "performance" ? Components.Theme.warning : Components.Theme.accent)
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    text: root.activePowerProfile === "power-saver"
                                          ? "󰌪"
                                          : (root.activePowerProfile === "performance" ? "󰓅" : "󰾆")
                                    color: Components.Theme.bg
                                    font.pixelSize: 24
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                width: parent.width - 66

                                Row {
                                    spacing: 6
                                    width: parent.width

                                    Text {
                                        text: "Power Settings"
                                        color: "#ffffff"
                                        font.pixelSize: 15
                                        font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // 3-step indicator pills [ Saver | Balanced | Perf ]
                                    Row {
                                        spacing: 3
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: root.activePowerProfile === "power-saver" ? Components.Theme.success : Components.Theme.fgMuted
                                        }
                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: root.activePowerProfile === "balanced" ? Components.Theme.accent : Components.Theme.fgMuted
                                        }
                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: root.activePowerProfile === "performance" ? Components.Theme.warning : Components.Theme.fgMuted
                                        }
                                    }
                                }

                                Text {
                                    text: root.activePowerProfile === "power-saver"
                                          ? "Power Saving • Eco"
                                          : (root.activePowerProfile === "performance"
                                             ? "Performance • Turbo"
                                             : "Balanced • Optimal")
                                    color: root.activePowerProfile === "power-saver"
                                           ? Components.Theme.success
                                           : (root.activePowerProfile === "performance" ? Components.Theme.warning : Components.Theme.accentTertiary)
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            id: powerTileMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Cycle: power-saver => balanced => performance => power-saver
                                if (root.activePowerProfile === "power-saver") {
                                    root.activePowerProfile = "balanced"
                                } else if (root.activePowerProfile === "balanced") {
                                    root.activePowerProfile = "performance"
                                } else {
                                    root.activePowerProfile = "power-saver"
                                }
                                Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/powerprofile.sh", "set", root.activePowerProfile])
                                powerProcess.running = true
                            }
                        }
                    }

                    // Tile 4: Microphone (Full button color changes when Muted!)
                    Rectangle {
                        width: (parent.width - 14) / 2
                        height: 74
                        radius: 14
                        color: root.isMicMuted
                               ? (micMouse.containsMouse ? Qt.darker(Components.Theme.danger, 2.2) : Qt.darker(Components.Theme.danger, 2.8))
                               : (micMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface)
                        border.color: root.isMicMuted ? Components.Theme.danger : Components.Theme.surfaceHover
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Rectangle {
                                width: 48
                                height: 48
                                radius: 12
                                color: root.isMicMuted ? Components.Theme.danger : Components.Theme.bg
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: root.isMicMuted ? "󰍭" : "󰍬"
                                    color: root.isMicMuted ? Components.Theme.bg : Components.Theme.success
                                    font.pixelSize: 24
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                width: parent.width - 66

                                Text {
                                    text: "Microphone"
                                    color: root.isMicMuted ? "#ffffff" : Components.Theme.fg
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: root.isMicMuted ? "Muted (Mic Off)" : "Active / Live"
                                    color: root.isMicMuted ? Components.Theme.danger : Components.Theme.success
                                    font.pixelSize: 13
                                }
                            }
                        }

                        MouseArea {
                            id: micMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
                                micProcess.running = true
                            }
                        }
                    }

                    // Tile 4: Screenshot
                    Rectangle {
                        width: (parent.width - 14) / 2
                        height: 74
                        radius: 14
                        color: shotMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                        border.color: shotMouse.containsMouse ? Components.Theme.accentSecondary : Components.Theme.surfaceHover
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Rectangle {
                                width: 48
                                height: 48
                                radius: 12
                                color: Components.Theme.bg
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: "󰹑"
                                    color: Components.Theme.accentSecondary
                                    font.pixelSize: 24
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                width: parent.width - 66

                                Text {
                                    text: "Screenshot"
                                    color: Components.Theme.fg
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: "Select area capture"
                                    color: Components.Theme.fgMuted
                                    font.pixelSize: 13
                                }
                            }
                        }

                        MouseArea {
                            id: shotMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                Quickshell.execDetached(["sh", "-c", "mkdir -p ~/SCREEN/screenshots && grim -g \"$(slurp)\" ~/SCREEN/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png && notify-send 'Screenshot' 'Area saved to ~/SCREEN/screenshots' -i camera-photo"])
                            }
                        }
                    }

                    // Tile 5: Screen Record (Full button color changes when Recording!)
                    Rectangle {
                        width: (parent.width - 14) / 2
                        height: 74
                        radius: 14
                        color: root.recordStatus !== "idle"
                               ? (recTileMouse.containsMouse ? Qt.darker(Components.Theme.danger, 2.0) : Qt.darker(Components.Theme.danger, 2.5))
                               : (recTileMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface)
                        border.color: root.recordStatus !== "idle" ? Components.Theme.danger : Components.Theme.surfaceHover
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Rectangle {
                                width: 48
                                height: 48
                                radius: 12
                                color: root.recordStatus !== "idle" ? Components.Theme.danger : Components.Theme.bg
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: "󰻃"
                                    color: root.recordStatus !== "idle" ? Components.Theme.bg : Components.Theme.danger
                                    font.pixelSize: 24
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                width: parent.width - 66

                                Text {
                                    text: "Screen Record"
                                    color: root.recordStatus !== "idle" ? "#ffffff" : Components.Theme.fg
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: root.recordStatus !== "idle" ? "Recording Active!" : "Select region to record"
                                    color: root.recordStatus !== "idle" ? Components.Theme.danger : Components.Theme.fgMuted
                                    font.pixelSize: 13
                                }
                            }
                        }

                        MouseArea {
                            id: recTileMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                if (root.recordStatus !== "idle") {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/screencast.sh", "stop"])
                                } else {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/screencast.sh", "start"])
                                }
                                recStatusProcess.running = true
                            }
                        }
                    }
                }

                // 1-Click System Themes Studio Banner
                Rectangle {
                    width: parent.width
                    height: 54
                    radius: 14
                    color: themeStudioMouse.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
                    border.color: themeStudioMouse.containsMouse ? Components.Theme.accent : Components.Theme.border
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Rectangle {
                            width: 38
                            height: 38
                            radius: 12
                            color: Components.Theme.accent
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "󰏘"
                                color: Components.Theme.bg
                                font.pixelSize: 20
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 38 - 14 - 30

                            Row {
                                spacing: 8
                                Text {
                                    text: "System Themes"
                                    color: Components.Theme.fg
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: activeThemeBadgeText.implicitWidth + 12
                                    height: 18
                                    radius: 9
                                    color: Components.Theme.surfaceHover
                                    border.color: Components.Theme.accent
                                    border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: activeThemeBadgeText
                                        text: root.activeThemeName
                                        color: Components.Theme.accent
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                            Text {
                                text: "1-Click Whole-System Theme Switcher (7 Curated Presets)"
                                color: Components.Theme.fgMuted
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            text: "󰅂"
                            color: themeStudioMouse.containsMouse ? Components.Theme.accent : Components.Theme.fgMuted
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: themeStudioMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isSettingsOpen = false
                            root.isThemesOpen = true
                            themesListProcess.running = true
                        }
                    }
                }

                // Wallpaper & Canvas Setter Banner (Full width)
                Rectangle {
                    width: parent.width
                    height: 52
                    radius: 12
                    color: wallTileMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                    border.color: wallTileMouse.containsMouse ? Components.Theme.accent : Components.Theme.surfaceHover
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Rectangle {
                            width: 38
                            height: 38
                            radius: 10
                            color: Components.Theme.bg
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "󰸉"
                                color: Components.Theme.accent
                                font.pixelSize: 20
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 38 - 14 - 30

                            Text {
                                text: "Web Wallpaper Studio"
                                color: Components.Theme.fg
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: "HTML5/WebGL Themes, Live Effects & FX"
                                color: Components.Theme.fgMuted
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            text: "󰅂"
                            color: wallTileMouse.containsMouse ? Components.Theme.accent : Components.Theme.fgMuted
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: wallTileMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isSettingsOpen = false
                            root.isGalleryOpen = true
                            listProcess.running = true
                            activeProcess.running = true
                            configProcess.running = true
                            statusProcess.running = true
                        }
                    }
                }

                // 1-Click Bar Layout / Style Selector (Floating | Islands | Normal | Compact)
                Rectangle {
                    width: parent.width
                    height: 56
                    radius: 14
                    color: Components.Theme.surface
                    border.color: Components.Theme.border
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 5

                        Row {
                            spacing: 6
                            anchors.left: parent.left
                            anchors.leftMargin: 4

                            Text {
                                text: "󰓩"
                                color: Components.Theme.accent
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Bar Style"
                                color: Components.Theme.fg
                                font.pixelSize: 12
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "• " + (Components.Theme.barStyle === "floating" ? "Floating Neo-Glass" : (Components.Theme.barStyle === "islands" ? "Split 3-Islands" : (Components.Theme.barStyle === "normal" ? "Classic Edge-to-Edge" : "Compact Minimal")))
                                color: Components.Theme.accentSecondary
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: [
                                    { id: "floating", label: "Floating", icon: "󰹬" },
                                    { id: "islands", label: "Islands", icon: "󰮊" },
                                    { id: "normal", label: "Normal", icon: "󰵊" },
                                    { id: "compact", label: "Compact", icon: "󰍹" }
                                ]

                                delegate: Rectangle {
                                    width: (parent.width - (3 * 6)) / 4
                                    height: 25
                                    radius: 7
                                    color: Components.Theme.barStyle === modelData.id
                                           ? Components.Theme.accent
                                           : (barOptMouse.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surfaceCard)
                                    border.color: Components.Theme.barStyle === modelData.id
                                                  ? Components.Theme.accent
                                                  : Components.Theme.border
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: modelData.icon
                                            color: Components.Theme.barStyle === modelData.id ? Components.Theme.bg : (barOptMouse.containsMouse ? Components.Theme.accent : Components.Theme.fg)
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: modelData.label
                                            color: Components.Theme.barStyle === modelData.id ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 10
                                            font.bold: Components.Theme.barStyle === modelData.id
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: barOptMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Components.Theme.setBarStyle(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Components.Theme.bgAlt
                }

                // 2. Interactive Brightness Slider (Before Volume)
                Item {
                    width: parent.width
                    height: 44

                    Text {
                        id: brightIcon
                        text: "󰃠"
                        color: Components.Theme.warning
                        font.pixelSize: 24
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: brightVal
                        text: root.brightnessLevel + "%"
                        color: Components.Theme.warning
                        font.pixelSize: 15
                        font.bold: true
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 48
                        horizontalAlignment: Text.AlignRight
                    }

                    // Interactive Slider Track
                    Rectangle {
                        id: brightTrack
                        anchors.left: brightIcon.right
                        anchors.leftMargin: 16
                        anchors.right: brightVal.left
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        height: 10
                        radius: 5
                        color: Components.Theme.bg

                        Rectangle {
                            width: parent.width * (root.brightnessLevel / 100)
                            height: parent.height
                            radius: 5
                            color: Components.Theme.warning
                        }

                        // Slider Knob
                        Rectangle {
                            x: Math.min(Math.max(0, parent.width * (root.brightnessLevel / 100) - 10), parent.width - 20)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            radius: 10
                            color: Components.Theme.warning
                            border.color: "#ffffff"
                            border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -12
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            function setBrightFromMouse(mouseX) {
                                let ratio = Math.max(0.05, Math.min(1, mouseX / brightTrack.width))
                                let newBright = Math.round(ratio * 100)
                                root.brightnessLevel = newBright
                                Quickshell.execDetached(["brightnessctl", "set", newBright.toString() + "%"])
                            }

                            onPressed: (mouse) => setBrightFromMouse(mouse.x)
                            onPositionChanged: (mouse) => {
                                if (pressed) setBrightFromMouse(mouse.x)
                            }
                        }
                    }
                }

                // 3. Interactive Volume Slider
                Item {
                    width: parent.width
                    height: 44

                    Text {
                        id: volIcon
                        text: root.isAudioMuted ? "󰖁" : (root.volumeLevel > 50 ? "󰕾" : "󰕿")
                        color: root.isAudioMuted ? Components.Theme.danger : Components.Theme.accent
                        font.pixelSize: 24
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                                audioProcess.running = true
                            }
                        }
                    }

                    Text {
                        id: volVal
                        text: root.volumeLevel + "%"
                        color: Components.Theme.accentTertiary
                        font.pixelSize: 15
                        font.bold: true
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 48
                        horizontalAlignment: Text.AlignRight
                    }

                    // Interactive Slider Track
                    Rectangle {
                        id: volTrack
                        anchors.left: volIcon.right
                        anchors.leftMargin: 16
                        anchors.right: volVal.left
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        height: 10
                        radius: 5
                        color: Components.Theme.bg

                        Rectangle {
                            width: parent.width * (root.volumeLevel / 100)
                            height: parent.height
                            radius: 5
                            color: root.isAudioMuted ? Components.Theme.fgMuted : Components.Theme.accent
                        }

                        // Slider Knob
                        Rectangle {
                            x: Math.min(Math.max(0, parent.width * (root.volumeLevel / 100) - 10), parent.width - 20)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            radius: 10
                            color: root.isAudioMuted ? Components.Theme.fgMuted : Components.Theme.accent
                            border.color: "#ffffff"
                            border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -12
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            function setVolFromMouse(mouseX) {
                                let ratio = Math.max(0, Math.min(1, mouseX / volTrack.width))
                                let newVol = Math.round(ratio * 100)
                                root.volumeLevel = newVol
                                Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", (ratio.toFixed(2)).toString()])
                            }

                            onPressed: (mouse) => setVolFromMouse(mouse.x)
                            onPositionChanged: (mouse) => {
                                if (pressed) setVolFromMouse(mouse.x)
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Components.Theme.bgAlt
                }

                // 4. Bottom System Action Buttons (Including Shutdown and Sudo Shutdown Now!)
                Grid {
                    width: parent.width
                    columns: 3
                    spacing: 10

                    // 1. Refresh Niri
                    Rectangle {
                        width: (parent.width - 20) / 3
                        height: 44
                        radius: 10
                        color: reloadMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                        border.color: reloadMouse.containsMouse ? Components.Theme.accentTertiary : Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰑐"; color: Components.Theme.accentTertiary; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Refresh Niri"; color: Components.Theme.fg; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: reloadMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                Quickshell.execDetached(["sh", "-c", "$HOME/DARK_NIRI/quickshell/reload-shell.sh"])
                            }
                        }
                    }

                    // 2. Lock Screen
                    Rectangle {
                        width: (parent.width - 20) / 3
                        height: 44
                        radius: 10
                        color: lockMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                        border.color: lockMouse.containsMouse ? Components.Theme.accent : Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰌾"; color: Components.Theme.accent; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Lock Screen"; color: Components.Theme.fg; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: lockMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                Quickshell.execDetached(["sh", "-c", "swaylock -f || niri msg action power-off-monitors"])
                            }
                        }
                    }

                    // 3. Log Out
                    Rectangle {
                        width: (parent.width - 20) / 3
                        height: 44
                        radius: 10
                        color: exitMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                        border.color: exitMouse.containsMouse ? Components.Theme.accentSecondary : Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰍃"; color: Components.Theme.accentSecondary; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Log Out"; color: Components.Theme.fg; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: exitMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                Quickshell.execDetached(["niri", "msg", "action", "quit"])
                            }
                        }
                    }

                    // 4. Restart
                    Rectangle {
                        width: (parent.width - 20) / 3
                        height: 44
                        radius: 10
                        color: rebootMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                        border.color: rebootMouse.containsMouse ? Components.Theme.warning : Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰜉"; color: Components.Theme.warning; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Restart"; color: Components.Theme.fg; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: rebootMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                Quickshell.execDetached(["systemctl", "reboot"])
                            }
                        }
                    }

                    // 5. Shutdown (Normal)
                    Rectangle {
                        width: (parent.width - 20) / 3
                        height: 44
                        radius: 10
                        color: shutMouse.containsMouse ? Qt.darker(Components.Theme.danger, 3.0) : Components.Theme.surface
                        border.color: shutMouse.containsMouse ? Components.Theme.danger : Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰐥"; color: Components.Theme.danger; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Shutdown"; color: Components.Theme.fg; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: shutMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/shutdown.sh"])
                            }
                        }
                    }

                    // 6. Sudo Shutdown Now (Prompts password for sudo!)
                    Rectangle {
                        width: (parent.width - 20) / 3
                        height: 44
                        radius: 10
                        color: sudoShutMouse.containsMouse ? Components.Theme.danger : Qt.darker(Components.Theme.danger, 3.5)
                        border.color: Components.Theme.danger
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "󰐦"
                                color: sudoShutMouse.containsMouse ? Components.Theme.bg : Components.Theme.danger
                                font.pixelSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Sudo Off Now"
                                color: sudoShutMouse.containsMouse ? Components.Theme.bg : Components.Theme.danger
                                font.pixelSize: 13
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: sudoShutMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/shutdown.sh", "sudo"])
                            }
                        }
                    }
                }
            }
        }
    }

    // Dedicated Whole-System Theme Studio Modal (Anchored Top-Right, Slide Animation)
    PopupWindow {
        id: themesPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(barWindow.width - 560 - 20)
        anchor.rect.y: Math.round(barWindow.height + 4)
        anchor.rect.width: 560
        anchor.rect.height: 1

        implicitWidth: 560
        implicitHeight: 660
        visible: root.isThemesOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Components.Theme.bgAlpha
            border.color: Components.Theme.border
            border.width: 1

            // Top-right slide in animation
            transform: Translate {
                x: root.isThemesOpen ? 0 : 30
                y: root.isThemesOpen ? 0 : -15
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            opacity: root.isThemesOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header
                Item {
                    width: parent.width
                    height: 40

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 38
                            height: 38
                            radius: 12
                            color: Components.Theme.surface
                            border.color: Components.Theme.accent
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "󰏘"
                                color: Components.Theme.accent
                                font.pixelSize: 22
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Theme Studio"
                                color: Components.Theme.fg
                                font.pixelSize: 18
                                font.bold: true
                            }
                            Text {
                                text: "1-Click Whole Dotfiles Theme Orchestrator"
                                color: Components.Theme.fgMuted
                                font.pixelSize: 12
                            }
                        }
                    }

                    // Close Button
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        radius: 16
                        color: closeThemeMouse.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface
                        border.color: Components.Theme.border
                        border.width: 1

                        Text {
                            text: "󰅖"
                            color: Components.Theme.fg
                            font.pixelSize: 16
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: closeThemeMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isThemesOpen = false
                        }
                    }
                }

                // Subtitle Info Banner
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 10
                    color: Components.Theme.surface
                    border.color: Components.Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰄬"
                            color: Components.Theme.accent
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Synchronizes QuickShell, Niri, Rofi, Fuzzel, Mako & Wallpaper"
                            color: Components.Theme.fgSecondary
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Bar Style Layout Switcher in Theme Studio
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: Components.Theme.surface
                    border.color: Components.Theme.border
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 86

                            Text {
                                text: "󰓩"
                                color: Components.Theme.accent
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Bar Style"
                                color: Components.Theme.fg
                                font.pixelSize: 12
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 96
                            spacing: 6

                            Repeater {
                                model: [
                                    { id: "floating", label: "Floating", icon: "󰹬" },
                                    { id: "islands", label: "Islands", icon: "󰮊" },
                                    { id: "normal", label: "Normal", icon: "󰵊" },
                                    { id: "compact", label: "Compact", icon: "󰍹" }
                                ]

                                delegate: Rectangle {
                                    width: (parent.width - (3 * 6)) / 4
                                    height: 30
                                    radius: 8
                                    color: Components.Theme.barStyle === modelData.id
                                           ? Components.Theme.accent
                                           : (themeBarOptMouse.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surfaceCard)
                                    border.color: Components.Theme.barStyle === modelData.id
                                                  ? Components.Theme.accent
                                                  : Components.Theme.border
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: modelData.icon
                                            color: Components.Theme.barStyle === modelData.id ? Components.Theme.bg : (themeBarOptMouse.containsMouse ? Components.Theme.accent : Components.Theme.fg)
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: modelData.label
                                            color: Components.Theme.barStyle === modelData.id ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 10
                                            font.bold: Components.Theme.barStyle === modelData.id
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: themeBarOptMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Components.Theme.setBarStyle(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Theme Presets List
                ListView {
                    width: parent.width
                    height: 460
                    clip: true
                    spacing: 8
                    model: root.themesList

                    delegate: Rectangle {
                        width: parent.width
                        height: 60
                        radius: 12
                        color: modelData.is_active ? Components.Theme.surfaceHover : (themeItemMouse.containsMouse ? Components.Theme.surfaceCard : Components.Theme.surface)
                        border.color: modelData.is_active ? Components.Theme.accent : (themeItemMouse.containsMouse ? Components.Theme.accentSecondary : Components.Theme.border)
                        border.width: modelData.is_active ? 2 : 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            // Color Icon
                            Rectangle {
                                width: 38
                                height: 38
                                radius: 10
                                color: modelData.bg
                                border.color: modelData.is_active ? modelData.accent : modelData.border
                                border.width: 2
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: modelData.is_active ? "󰄬" : "󰏘"
                                    color: modelData.accent
                                    font.pixelSize: modelData.is_active ? 20 : 16
                                    anchors.centerIn: parent
                                }
                            }

                            // Info
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 240

                                Row {
                                    spacing: 6
                                    Text {
                                        text: modelData.name
                                        color: modelData.is_active ? modelData.accent : Components.Theme.fg
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    Rectangle {
                                        visible: modelData.is_active
                                        width: 48
                                        height: 16
                                        radius: 8
                                        color: modelData.accent
                                        Text {
                                            text: "ACTIVE"
                                            color: modelData.bg
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }
                                    }
                                }
                                Text {
                                    text: modelData.description
                                    color: Components.Theme.fgMuted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Swatches
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Rectangle { width: 16; height: 16; radius: 8; color: modelData.bg; border.color: Components.Theme.border; border.width: 1 }
                                Rectangle { width: 16; height: 16; radius: 8; color: modelData.surface; border.color: Components.Theme.border; border.width: 1 }
                                Rectangle { width: 16; height: 16; radius: 8; color: modelData.accent; border.color: "#ffffff"; border.width: 1 }
                                Rectangle { width: 16; height: 16; radius: 8; color: modelData.accent_secondary; border.color: "#ffffff"; border.width: 1 }
                            }

                            // Apply Button
                            Rectangle {
                                width: 68
                                height: 30
                                radius: 8
                                color: modelData.is_active ? modelData.accent : (applyMouse.containsMouse ? Components.Theme.surfaceHover : Components.Theme.surface)
                                border.color: modelData.is_active ? modelData.accent : Components.Theme.border
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: modelData.is_active ? "Applied" : "Apply"
                                    color: modelData.is_active ? modelData.bg : Components.Theme.fg
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: applyMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme-manager", "apply", modelData.id])
                                        themesListProcess.running = true
                                        Components.Theme.refresh()
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: themeItemMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/theme-manager", "apply", modelData.id])
                                themesListProcess.running = true
                                Components.Theme.refresh()
                            }
                        }
                    }
                }
            }
        }
    }

    // Dedicated Notification Center Modal (Anchored Top-Right, Slide Animation)
    PopupWindow {
        id: notifPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(barWindow.width - 540 - 20)
        anchor.rect.y: Math.round(barWindow.height + 4)
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 520
        visible: root.isNotifOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Components.Theme.bgAlpha
            border.color: Components.Theme.border
            border.width: 1

            // Top-right slide in animation
            transform: Translate {
                x: root.isNotifOpen ? 0 : 30
                y: root.isNotifOpen ? 0 : -15
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            opacity: root.isNotifOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header
                Item {
                    width: parent.width
                    height: 46

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text { text: "󰂚"; color: Components.Theme.accent; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: "Notifications"; color: Components.Theme.fg; font.pixelSize: 16; font.bold: true }
                            Text {
                                text: root.notifications.length > 0 ? (root.notifications.length + " alerts in history") : "No new notifications"
                                color: Components.Theme.fgMuted
                                font.pixelSize: 12
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Clear All Button
                        Rectangle {
                            visible: root.notifications.length > 0
                            width: 88
                            height: 32
                            radius: 8
                            color: clearAllMouse.containsMouse ? Components.Theme.danger : Components.Theme.surface
                            border.color: clearAllMouse.containsMouse ? Components.Theme.danger : Components.Theme.border
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "󰎟"
                                    color: clearAllMouse.containsMouse ? Components.Theme.bg : Components.Theme.danger
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: "Clear All"
                                    color: clearAllMouse.containsMouse ? Components.Theme.bg : Components.Theme.fg
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: clearAllMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/notifications.sh", "clear"])
                                    notifProcess.running = true
                                }
                            }
                        }

                        // Close Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: notifCloseMouse.containsMouse ? Components.Theme.danger : Components.Theme.surface
                            border.color: notifCloseMouse.containsMouse ? Components.Theme.danger : Components.Theme.border
                            border.width: 1

                            Text { text: "󰅖"; color: notifCloseMouse.containsMouse ? Components.Theme.bg : Components.Theme.fg; font.pixelSize: 14; anchors.centerIn: parent }

                            MouseArea {
                                id: notifCloseMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.isNotifOpen = false
                            }
                        }
                    }
                }

                // Divider
                Rectangle { width: parent.width; height: 1; color: Components.Theme.bgAlt }

                // Empty State View
                Item {
                    visible: root.notifications.length === 0
                    width: parent.width
                    height: 380

                    Column {
                        anchors.centerIn: parent
                        spacing: 12
                        Text { text: "󰂜"; color: Components.Theme.border; font.pixelSize: 52; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "No Notifications"; color: Components.Theme.fg; font.pixelSize: 15; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "You're all caught up!"; color: Components.Theme.fgMuted; font.pixelSize: 13; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                // Scrollable Notifications List
                Flickable {
                    visible: root.notifications.length > 0
                    width: parent.width
                    height: 410
                    contentHeight: notifCol.height
                    clip: true

                    Column {
                        id: notifCol
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.notifications

                            delegate: Rectangle {
                                width: notifCol.width
                                height: notifCardCol.implicitHeight + 20
                                radius: 12
                                color: itemHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.bg
                                border.color: itemHover.containsMouse ? Components.Theme.accent : Components.Theme.surfaceHover
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    id: notifCardCol
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.right: dismissBtn.left
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Row {
                                        spacing: 8
                                        // App Badge
                                        Rectangle {
                                            width: appTxt.implicitWidth + 10
                                            height: 18
                                            radius: 4
                                            color: Components.Theme.surface
                                            border.color: Components.Theme.border
                                            border.width: 1

                                            Text {
                                                id: appTxt
                                                text: modelData.app
                                                color: Components.Theme.accentTertiary
                                                font.pixelSize: 10
                                                font.bold: true
                                                anchors.centerIn: parent
                                            }
                                        }

                                        Text {
                                            text: modelData.summary
                                            color: Components.Theme.fg
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: notifCardCol.width - appTxt.implicitWidth - 25
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Text {
                                        visible: modelData.body !== ""
                                        text: modelData.body
                                        color: Components.Theme.fgSecondary
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                        width: notifCardCol.width
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }
                                }

                                // Clear Single Notification Button
                                Rectangle {
                                    id: dismissBtn
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: delHover.containsMouse ? Components.Theme.danger : Components.Theme.surface
                                    border.color: delHover.containsMouse ? Components.Theme.danger : Components.Theme.border
                                    border.width: 1

                                    Text {
                                        text: "󰅖"
                                        color: delHover.containsMouse ? Components.Theme.bg : Components.Theme.fgMuted
                                        font.pixelSize: 12
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: delHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/notifications.sh", "dismiss", modelData.id.toString()])
                                            notifProcess.running = true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: itemHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dedicated Full-Featured Wi-Fi Manager Modal (Anchored Top-Right, Slide Animation)
    PopupWindow {
        id: wifiPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(barWindow.width - 540 - 20)
        anchor.rect.y: Math.round(barWindow.height + 4)
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 520
        visible: root.isWifiOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Components.Theme.bgAlpha
            border.color: Components.Theme.border
            border.width: 1

            // Top-right slide in animation
            transform: Translate {
                x: root.isWifiOpen ? 0 : 30
                y: root.isWifiOpen ? 0 : -15
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            opacity: root.isWifiOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header
                Item {
                    width: parent.width
                    height: 48

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text { text: "󰤨"; color: Components.Theme.accent; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: "Wi-Fi Networks"; color: Components.Theme.fg; font.pixelSize: 16; font.bold: true }
                            Text { text: "Manage & connect to wireless networks"; color: Components.Theme.fgMuted; font.pixelSize: 12 }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Wi-Fi On/Off Switch Button
                        Rectangle {
                            width: 105
                            height: 34
                            radius: 17
                            color: root.wifiEnabled ? Components.Theme.accent : Components.Theme.surface
                            border.color: root.wifiEnabled ? Components.Theme.accent : Components.Theme.border
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: root.wifiEnabled ? "󰤨  Wi-Fi ON" : "󰤭  Wi-Fi OFF"
                                    color: root.wifiEnabled ? Components.Theme.bg : Components.Theme.fgMuted
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "toggle"])
                                    wifiListProcess.running = true
                                }
                            }
                        }

                        // Rescan Button
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: wifiRescanMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                            border.color: wifiRescanMouse.containsMouse ? Components.Theme.accent : Components.Theme.border
                            border.width: 1

                            Text { text: "󰑐"; color: wifiRescanMouse.containsMouse ? Components.Theme.accent : Components.Theme.fg; font.pixelSize: 14; anchors.centerIn: parent }

                            MouseArea {
                                id: wifiRescanMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "rescan"])
                                    wifiListProcess.running = true
                                }
                            }
                        }

                        // Close Button
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: wifiCloseMouse.containsMouse ? Components.Theme.danger : Components.Theme.surface
                            border.color: wifiCloseMouse.containsMouse ? Components.Theme.danger : Components.Theme.border
                            border.width: 1

                            Text { text: "󰅖"; color: wifiCloseMouse.containsMouse ? Components.Theme.bg : Components.Theme.fg; font.pixelSize: 14; anchors.centerIn: parent }

                            MouseArea {
                                id: wifiCloseMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isWifiOpen = false
                                    root.wifiSelectedSsid = ""
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle { width: parent.width; height: 1; color: Components.Theme.bgAlt }

                // Scrollable Available Networks List
                Flickable {
                    width: parent.width
                    height: 410
                    contentHeight: wifiCol.height
                    clip: true

                    Column {
                        id: wifiCol
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.wifiNetworks

                            delegate: Rectangle {
                                width: wifiCol.width
                                height: 60
                                radius: 12
                                color: modelData.connected
                                       ? Qt.darker(Components.Theme.accent, 2.5)
                                       : (netHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.bg)
                                border.color: modelData.connected ? Components.Theme.accent : Components.Theme.surfaceHover
                                border.width: modelData.connected ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10

                                    // Signal Icon
                                    Text {
                                        text: modelData.signal > 75 ? "󰤨" : (modelData.signal > 50 ? "󰤥" : (modelData.signal > 25 ? "󰤢" : "󰤟"))
                                        color: modelData.connected ? Components.Theme.accentTertiary : Components.Theme.accent
                                        font.pixelSize: 22
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Row {
                                            spacing: 6

                                            Text {
                                                text: modelData.ssid
                                                color: modelData.connected ? "#ffffff" : Components.Theme.fg
                                                font.pixelSize: 13
                                                font.bold: true
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            // Wi-Fi Band Badge
                                            Rectangle {
                                                visible: modelData.band !== ""
                                                width: bandText.implicitWidth + 8
                                                height: 18
                                                radius: 4
                                                color: Components.Theme.surface
                                                border.color: Components.Theme.border
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    id: bandText
                                                    text: modelData.band || "2.4 GHz"
                                                    color: Components.Theme.accent
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    anchors.centerIn: parent
                                                }
                                            }

                                            // Security badge
                                            Text {
                                                visible: modelData.security !== "Open"
                                                text: "󰌾 " + modelData.security
                                                color: Components.Theme.fgMuted
                                                font.pixelSize: 11
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            // WPS ON Badge
                                            Rectangle {
                                                visible: modelData.wps
                                                width: 68
                                                height: 18
                                                radius: 4
                                                color: Qt.darker(Components.Theme.success, 3.0)
                                                border.color: Components.Theme.success
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    text: "󰖩 WPS ON"
                                                    color: Components.Theme.success
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    anchors.centerIn: parent
                                                }
                                            }
                                        }

                                        Text {
                                            text: modelData.connected
                                                  ? "Connected & Active"
                                                  : (modelData.wps
                                                     ? "WPS ON • Tap to connect"
                                                     : (modelData.saved ? "Saved • Signal: " + modelData.signal + "%" : "Available • Signal: " + modelData.signal + "%"))
                                            color: modelData.connected ? Components.Theme.accentTertiary : (modelData.wps ? Components.Theme.success : Components.Theme.fgMuted)
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                // Action Buttons on Right (Disconnect / WPS Connect / Connect / Forget)
                                Row {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6

                                    // Disconnect Button
                                    Rectangle {
                                        visible: modelData.connected
                                        width: 82
                                        height: 30
                                        radius: 6
                                        color: disMouse.containsMouse ? Components.Theme.danger : Components.Theme.surface
                                        border.color: Components.Theme.danger
                                        border.width: 1

                                        Text {
                                            text: "Disconnect"
                                            color: disMouse.containsMouse ? Components.Theme.bg : Components.Theme.danger
                                            font.pixelSize: 11
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            id: disMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "disconnect"])
                                                wifiListProcess.running = true
                                            }
                                        }
                                    }

                                    // Forget Button
                                    Rectangle {
                                        visible: modelData.saved && !modelData.connected
                                        width: 64
                                        height: 30
                                        radius: 6
                                        color: forMouse.containsMouse ? Components.Theme.danger : Components.Theme.surface
                                        border.color: forMouse.containsMouse ? Components.Theme.danger : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: "Forget"
                                            color: forMouse.containsMouse ? Components.Theme.bg : Components.Theme.fgMuted
                                            font.pixelSize: 11
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            id: forMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "forget", modelData.ssid])
                                                wifiListProcess.running = true
                                            }
                                        }
                                    }

                                    // Connect Button
                                    Rectangle {
                                        visible: !modelData.connected
                                        width: modelData.wps ? 88 : 72
                                        height: 30
                                        radius: 6
                                        color: connMouse.containsMouse ? (modelData.wps ? Components.Theme.success : Components.Theme.accent) : Components.Theme.surface
                                        border.color: modelData.wps ? Components.Theme.success : Components.Theme.accent
                                        border.width: 1

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                visible: modelData.wps
                                                text: "󰖩"
                                                color: connMouse.containsMouse ? Components.Theme.bg : Components.Theme.success
                                                font.pixelSize: 11
                                            }
                                            Text {
                                                text: "Connect"
                                                color: connMouse.containsMouse ? Components.Theme.bg : (modelData.wps ? Components.Theme.success : Components.Theme.accent)
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }

                                        MouseArea {
                                            id: connMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.wps || modelData.saved || modelData.security === "Open") {
                                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "wps", modelData.ssid])
                                                    wifiRefreshTimer.restart()
                                                } else {
                                                    root.wifiSelectedSsid = modelData.ssid
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: netHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: modelData.connected ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    z: -1
                                    onClicked: {
                                        if (!modelData.connected) {
                                            if (modelData.wps || modelData.saved || modelData.security === "Open") {
                                                Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "wps", modelData.ssid])
                                                wifiRefreshTimer.restart()
                                            } else {
                                                root.wifiSelectedSsid = modelData.ssid
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

    // Dedicated Full-Featured Bluetooth Manager Modal (Anchored Top-Right, Slide Animation)
    PopupWindow {
        id: btPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(barWindow.width - 540 - 20)
        anchor.rect.y: Math.round(barWindow.height + 4)
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 520
        visible: root.isBtOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Components.Theme.bgAlpha
            border.color: Components.Theme.border
            border.width: 1

            // Top-right slide in animation
            transform: Translate {
                x: root.isBtOpen ? 0 : 30
                y: root.isBtOpen ? 0 : -15
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            opacity: root.isBtOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header
                Item {
                    width: parent.width
                    height: 48

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text { text: "󰂯"; color: Components.Theme.accentTertiary; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: "Bluetooth Devices"; color: Components.Theme.fg; font.pixelSize: 16; font.bold: true }
                            Text { text: "Pair, connect, and audio profiles"; color: Components.Theme.fgMuted; font.pixelSize: 12 }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Bluetooth On/Off Switch Button
                        Rectangle {
                            width: 120
                            height: 34
                            radius: 17
                            color: root.isBtOn ? Components.Theme.accentTertiary : Components.Theme.surface
                            border.color: root.isBtOn ? Components.Theme.accentTertiary : Components.Theme.border
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: root.isBtOn ? "󰂯  BT ON" : "󰂲  BT OFF"
                                    color: root.isBtOn ? Components.Theme.bg : Components.Theme.fgMuted
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bluetooth.sh", "toggle"])
                                    btListProcess.running = true
                                }
                            }
                        }

                        // Scan Button
                        Rectangle {
                            width: 65
                            height: 34
                            radius: 17
                            color: btScanMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                            border.color: btScanMouse.containsMouse ? Components.Theme.accentTertiary : Components.Theme.border
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text { text: "󰑐"; color: Components.Theme.accentTertiary; font.pixelSize: 13 }
                                Text { text: "Scan"; color: Components.Theme.fg; font.pixelSize: 11; font.bold: true }
                            }

                            MouseArea {
                                id: btScanMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bluetooth.sh", "scan"])
                                    btListProcess.running = true
                                }
                            }
                        }

                        // Close Button
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: btCloseMouse.containsMouse ? Components.Theme.danger : Components.Theme.surface
                            border.color: btCloseMouse.containsMouse ? Components.Theme.danger : Components.Theme.border
                            border.width: 1

                            Text { text: "󰅖"; color: btCloseMouse.containsMouse ? Components.Theme.bg : Components.Theme.fg; font.pixelSize: 14; anchors.centerIn: parent }

                            MouseArea {
                                id: btCloseMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.isBtOpen = false
                            }
                        }
                    }
                }

                // Divider
                Rectangle { width: parent.width; height: 1; color: Components.Theme.bgAlt }

                // Scrollable Bluetooth Devices List
                Flickable {
                    width: parent.width
                    height: 410
                    contentHeight: btCol.height
                    clip: true

                    Column {
                        id: btCol
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.btDevices

                            delegate: Rectangle {
                                width: btCol.width
                                height: (modelData.profiles && modelData.profiles.length > 0 && modelData.connected) ? 92 : 60
                                radius: 12
                                color: modelData.connected
                                       ? Qt.darker(Components.Theme.accentTertiary, 3.0)
                                       : (btDevHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.bg)
                                border.color: modelData.connected ? Components.Theme.accentTertiary : Components.Theme.surfaceHover
                                border.width: modelData.connected ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    // Top Row: Icon, Name, Battery, Status, Action Buttons
                                    Item {
                                        width: parent.width
                                        height: 36

                                        Row {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 10

                                            // Device Icon
                                            Text {
                                                text: modelData.icon.indexOf("headset") !== -1 || modelData.icon.indexOf("audio") !== -1
                                                      ? "󰋋"
                                                      : (modelData.icon.indexOf("phone") !== -1
                                                         ? "󰄡"
                                                         : (modelData.icon.indexOf("keyboard") !== -1 ? "󰌌" : (modelData.icon.indexOf("mouse") !== -1 ? "󰍽" : "󰂯")))
                                                color: modelData.connected ? Components.Theme.accentTertiary : Components.Theme.accent
                                                font.pixelSize: 20
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 2

                                                Row {
                                                    spacing: 6
                                                    Text {
                                                        text: modelData.name || modelData.mac
                                                        color: modelData.connected ? "#ffffff" : Components.Theme.fg
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                    }

                                                    // Battery Badge
                                                    Rectangle {
                                                        visible: modelData.battery !== null
                                                        width: 48
                                                        height: 16
                                                        radius: 4
                                                        color: Qt.darker(Components.Theme.success, 2.8)
                                                        border.color: Components.Theme.success
                                                        border.width: 1
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        Text {
                                                            text: "󰥉 " + (modelData.battery || 100) + "%"
                                                            color: Components.Theme.success
                                                            font.pixelSize: 9
                                                            font.bold: true
                                                            anchors.centerIn: parent
                                                        }
                                                    }
                                                }

                                                Text {
                                                    text: modelData.connected
                                                          ? "Connected & Ready"
                                                          : (modelData.paired ? "Paired • " + modelData.mac : "Available • " + modelData.mac)
                                                    color: modelData.connected ? Components.Theme.accentTertiary : Components.Theme.fgMuted
                                                    font.pixelSize: 10
                                                }
                                            }
                                        }

                                        // Action Buttons (Connect / Disconnect / Pair / Forget)
                                        Row {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6

                                            // Disconnect Button
                                            Rectangle {
                                                visible: modelData.connected
                                                width: 80
                                                height: 28
                                                radius: 6
                                                color: btDisMouse.containsMouse ? Components.Theme.danger : Components.Theme.surface
                                                border.color: Components.Theme.danger
                                                border.width: 1

                                                Text {
                                                    text: "Disconnect"
                                                    color: btDisMouse.containsMouse ? Components.Theme.bg : Components.Theme.danger
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    id: btDisMouse
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bluetooth.sh", "disconnect", modelData.mac])
                                                        btListProcess.running = true
                                                    }
                                                }
                                            }

                                            // Connect Button
                                            Rectangle {
                                                visible: !modelData.connected && modelData.paired
                                                width: 70
                                                height: 28
                                                radius: 6
                                                color: btConnMouse.containsMouse ? Components.Theme.accentTertiary : Components.Theme.surface
                                                border.color: Components.Theme.accentTertiary
                                                border.width: 1

                                                Text {
                                                    text: "Connect"
                                                    color: btConnMouse.containsMouse ? Components.Theme.bg : Components.Theme.accentTertiary
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    id: btConnMouse
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bluetooth.sh", "connect", modelData.mac])
                                                        btListProcess.running = true
                                                    }
                                                }
                                            }

                                            // Pair Button
                                            Rectangle {
                                                visible: !modelData.paired
                                                width: 60
                                                height: 28
                                                radius: 6
                                                color: btPairMouse.containsMouse ? Components.Theme.accent : Components.Theme.surface
                                                border.color: Components.Theme.accent
                                                border.width: 1

                                                Text {
                                                    text: "Pair"
                                                    color: btPairMouse.containsMouse ? Components.Theme.bg : Components.Theme.accent
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    id: btPairMouse
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bluetooth.sh", "pair", modelData.mac])
                                                        btListProcess.running = true
                                                    }
                                                }
                                            }

                                            // Forget Button
                                            Rectangle {
                                                visible: modelData.paired && !modelData.connected
                                                width: 60
                                                height: 28
                                                radius: 6
                                                color: btForMouse.containsMouse ? Components.Theme.danger : Components.Theme.surface
                                                border.color: btForMouse.containsMouse ? Components.Theme.danger : Components.Theme.border
                                                border.width: 1

                                                Text {
                                                    text: "Forget"
                                                    color: btForMouse.containsMouse ? Components.Theme.bg : Components.Theme.fgMuted
                                                    font.pixelSize: 10
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    id: btForMouse
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bluetooth.sh", "forget", modelData.mac])
                                                        btListProcess.running = true
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Bottom Row: Audio Profiles Selector (A2DP vs HSP/HFP)
                                    Row {
                                        visible: modelData.profiles && modelData.profiles.length > 0 && modelData.connected
                                        spacing: 6

                                        Text {
                                            text: "󰓃 Profile:"
                                            color: Components.Theme.fgMuted
                                            font.pixelSize: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Repeater {
                                            model: modelData.profiles

                                            delegate: Rectangle {
                                                width: profText.implicitWidth + 12
                                                height: 22
                                                radius: 5
                                                color: modelData.id === modelData.active_profile || (modelData.active_profile && modelData.active_profile.indexOf(modelData.id) !== -1)
                                                       ? Components.Theme.accentTertiary
                                                       : (profMouse.containsMouse ? Components.Theme.bgAlt : Components.Theme.bg)
                                                border.color: modelData.id === modelData.active_profile ? Components.Theme.accentTertiary : Components.Theme.border
                                                border.width: 1

                                                Text {
                                                    id: profText
                                                    text: modelData.name
                                                    color: (modelData.id === modelData.active_profile || (modelData.active_profile && modelData.active_profile.indexOf(modelData.id) !== -1))
                                                           ? Components.Theme.bg
                                                           : Components.Theme.fg
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    id: profMouse
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/bluetooth.sh", "profile", modelData.mac, modelData.id])
                                                        btListProcess.running = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: btDevHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dedicated Web Wallpaper & Effects Studio Modal (Anchored Top-Right, Slide Animation)
    PopupWindow {
        id: galleryPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(barWindow.width - 820 - 20)
        anchor.rect.y: Math.round(barWindow.height + 4)
        anchor.rect.width: 820
        anchor.rect.height: 1

        implicitWidth: 820
        implicitHeight: 570
        visible: root.isGalleryOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Components.Theme.bgAlpha
            border.color: Components.Theme.border
            border.width: 1

            // Top-right slide in animation
            transform: Translate {
                x: root.isGalleryOpen ? 0 : 30
                y: root.isGalleryOpen ? 0 : -15
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
            opacity: root.isGalleryOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // Header
            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 56
                anchors.margins: 16

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 10
                        color: Components.Theme.bg
                        border.color: Components.Theme.accent
                        border.width: 1

                        Text {
                            text: "󰸉"
                            color: Components.Theme.accent
                            font.pixelSize: 20
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "Web Wallpaper Studio"
                            color: Components.Theme.fg
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            text: "HTML5/WebGL Engine & Real-Time Effect Customizer"
                            color: Components.Theme.fgMuted
                            font.pixelSize: 11
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // Status Pill
                    Rectangle {
                        height: 30
                        width: statusText.implicitWidth + 24
                        radius: 15
                        color: root.isEngineRunning ? Qt.darker(Components.Theme.success, 3.2) : Qt.darker(Components.Theme.danger, 3.5)
                        border.color: root.isEngineRunning ? Components.Theme.success : Components.Theme.danger
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: root.isEngineRunning ? Components.Theme.success : Components.Theme.danger
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id: statusText
                                text: root.isEngineRunning ? "Engine Online" : "Start Engine"
                                color: root.isEngineRunning ? Components.Theme.success : Components.Theme.danger
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.isEngineRunning) {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "start"]);
                                    refreshConfigTimer.running = true;
                                }
                            }
                        }
                    }

                    // Refresh Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: refreshHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                        border.color: refreshHover.containsMouse ? Components.Theme.accent : Components.Theme.border
                        border.width: 1

                        Text {
                            text: "󰑐"
                            color: refreshHover.containsMouse ? Components.Theme.accent : Components.Theme.fg
                            font.pixelSize: 14
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: refreshHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                listProcess.running = true
                                activeProcess.running = true
                                configProcess.running = true
                                statusProcess.running = true
                            }
                        }
                    }

                    // Close Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: closeHover.containsMouse ? Components.Theme.danger : Components.Theme.surface
                        border.color: closeHover.containsMouse ? Components.Theme.danger : Components.Theme.border
                        border.width: 1

                        Text {
                            text: "󰅖"
                            color: closeHover.containsMouse ? Components.Theme.bg : Components.Theme.fg
                            font.pixelSize: 14
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isGalleryOpen = false
                        }
                    }
                }
            }

            // Category Tab Bar (5 tabs)
            Rectangle {
                id: tabBar
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 42
                radius: 10
                color: Components.Theme.bg
                border.color: Components.Theme.surfaceHover
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    // Tab 0: Web Themes
                    Rectangle {
                        width: (parent.width - 16) / 5
                        height: parent.height
                        radius: 7
                        color: root.selectedTab === 0 ? Components.Theme.bgAlt : "transparent"
                        border.color: root.selectedTab === 0 ? Components.Theme.accent : "transparent"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰈹"; color: root.selectedTab === 0 ? Components.Theme.accent : Components.Theme.fgMuted; font.pixelSize: 13 }
                            Text { text: "Web Themes"; color: root.selectedTab === 0 ? Components.Theme.fg : Components.Theme.fgMuted; font.pixelSize: 11; font.bold: root.selectedTab === 0 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = 0
                        }
                    }

                    // Tab 1: Wallpapers (Images & Videos)
                    Rectangle {
                        width: (parent.width - 16) / 5
                        height: parent.height
                        radius: 7
                        color: root.selectedTab === 1 ? Components.Theme.bgAlt : "transparent"
                        border.color: root.selectedTab === 1 ? Components.Theme.accentSecondary : "transparent"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰋩"; color: root.selectedTab === 1 ? Components.Theme.accentSecondary : Components.Theme.fgMuted; font.pixelSize: 13 }
                            Text { text: "Wallpapers"; color: root.selectedTab === 1 ? Components.Theme.fg : Components.Theme.fgMuted; font.pixelSize: 11; font.bold: root.selectedTab === 1 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = 1
                        }
                    }

                    // Tab 2: Effects & FX
                    Rectangle {
                        width: (parent.width - 16) / 5
                        height: parent.height
                        radius: 7
                        color: root.selectedTab === 2 ? Components.Theme.bgAlt : "transparent"
                        border.color: root.selectedTab === 2 ? Components.Theme.accentTertiary : "transparent"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰒓"; color: root.selectedTab === 2 ? Components.Theme.accentTertiary : Components.Theme.fgMuted; font.pixelSize: 13 }
                            Text { text: "Effects & FX"; color: root.selectedTab === 2 ? Components.Theme.fg : Components.Theme.fgMuted; font.pixelSize: 11; font.bold: root.selectedTab === 2 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = 2
                        }
                    }

                    // Tab 3: Performance & Engine
                    Rectangle {
                        width: (parent.width - 16) / 5
                        height: parent.height
                        radius: 7
                        color: root.selectedTab === 3 ? Components.Theme.bgAlt : "transparent"
                        border.color: root.selectedTab === 3 ? Components.Theme.danger : "transparent"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰓅"; color: root.selectedTab === 3 ? Components.Theme.danger : Components.Theme.fgMuted; font.pixelSize: 13 }
                            Text { text: "Performance"; color: root.selectedTab === 3 ? Components.Theme.fg : Components.Theme.fgMuted; font.pixelSize: 11; font.bold: root.selectedTab === 3 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = 3
                        }
                    }

                    // Tab 4: Canvas Colors
                    Rectangle {
                        width: (parent.width - 16) / 5
                        height: parent.height
                        radius: 7
                        color: root.selectedTab === 4 ? Components.Theme.bgAlt : "transparent"
                        border.color: root.selectedTab === 4 ? Components.Theme.success : "transparent"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰏘"; color: root.selectedTab === 4 ? Components.Theme.success : Components.Theme.fgMuted; font.pixelSize: 13 }
                            Text { text: "Canvas Colors"; color: root.selectedTab === 4 ? Components.Theme.fg : Components.Theme.fgMuted; font.pixelSize: 11; font.bold: root.selectedTab === 4 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = 4
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                id: divider
                anchors.top: tabBar.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 1
                color: Components.Theme.surfaceHover
            }

            // TAB 0: Web Themes Grid
            Flickable {
                visible: root.selectedTab === 0
                anchors.top: divider.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                contentHeight: themeGrid.height
                clip: true

                Grid {
                    id: themeGrid
                    columns: 3
                    spacing: 14
                    width: parent.width

                    Repeater {
                        model: root.isGalleryOpen && root.selectedTab === 0 ? root.getFilteredWallpapers() : []

                        delegate: Rectangle {
                            width: (themeGrid.width - (themeGrid.spacing * 2)) / 3
                            height: 160
                            radius: 12
                            color: Components.Theme.bg
                            clip: true
                            border.color: root.activeWallpaper === modelData.path ? Components.Theme.accent : (themeHover.containsMouse ? Components.Theme.accentSecondary : Components.Theme.surfaceHover)
                            border.width: root.activeWallpaper === modelData.path ? 2 : 1

                            // Top gradient thumbnail
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 90
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: modelData.path === "cyber-city" ? Components.Theme.surface : (modelData.path === "aurora" ? "#142533" : (modelData.path === "cyber-matrix" ? Qt.darker(Components.Theme.success, 3.5) : Components.Theme.bgAlt)) }
                                    GradientStop { position: 1.0; color: Components.Theme.bg }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: modelData.path === "cyber-city" ? "󰈹" : (modelData.path === "aurora" ? "󰐊" : (modelData.path === "cyber-matrix" ? "󰘦" : "󰸉"))
                                        color: modelData.path === "cyber-matrix" ? Components.Theme.success : Components.Theme.accent
                                        font.pixelSize: 28
                                    }
                                }

                                // Interactive Pill
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 8
                                    height: 18
                                    width: 78
                                    radius: 9
                                    color: Qt.rgba(Qt.color(Components.Theme.bg).r, Qt.color(Components.Theme.bg).g, Qt.color(Components.Theme.bg).b, 0.5)
                                    border.color: Components.Theme.accent
                                    border.width: 1

                                    Text {
                                        text: "INTERACTIVE"
                                        color: Components.Theme.accent
                                        font.pixelSize: 8
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            // Info area
                            Column {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 10
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    color: root.activeWallpaper === modelData.path ? Components.Theme.accent : Components.Theme.fg
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.description || "Self-contained HTML theme"
                                    color: Components.Theme.fgMuted
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Active Checkmark Badge
                            Rectangle {
                                visible: root.activeWallpaper === modelData.path
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: 22
                                height: 22
                                radius: 11
                                color: Components.Theme.accent

                                Text {
                                    text: "✔"
                                    color: Components.Theme.bg
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }

                            MouseArea {
                                id: themeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "set", modelData.path])
                                    root.activeWallpaper = modelData.path
                                }
                            }
                        }
                    }
                }
            }

            // TAB 1: User Wallpapers Grid (Images & Videos)
            Flickable {
                visible: root.selectedTab === 1
                anchors.top: divider.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                contentHeight: wallGrid.height
                clip: true

                Grid {
                    id: wallGrid
                    columns: 3
                    spacing: 14
                    width: parent.width

                    Repeater {
                        model: root.isGalleryOpen && root.selectedTab === 1 ? root.getFilteredWallpapers() : []

                        delegate: Rectangle {
                            width: (wallGrid.width - (wallGrid.spacing * 2)) / 3
                            height: 155
                            radius: 12
                            color: Components.Theme.bg
                            clip: true
                            border.color: root.activeWallpaper === modelData.path ? Components.Theme.accentSecondary : (cardHover.containsMouse ? Components.Theme.accent : Components.Theme.surfaceHover)
                            border.width: root.activeWallpaper === modelData.path ? 2 : 1

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + (modelData.thumb ? modelData.thumb : modelData.path)
                                sourceSize.width: 320
                                sourceSize.height: 200
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 38
                                color: Qt.rgba(Qt.color(Components.Theme.bg).r, Qt.color(Components.Theme.bg).g, Qt.color(Components.Theme.bg).b, 0.85)

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.type === "video" ? "󰐊" : "󰋩"
                                        color: modelData.type === "video" ? Components.Theme.danger : Components.Theme.accent
                                        font.pixelSize: 13
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.name
                                        color: root.activeWallpaper === modelData.path ? Components.Theme.accentSecondary : Components.Theme.fg
                                        font.pixelSize: 11
                                        font.bold: root.activeWallpaper === modelData.path
                                        elide: Text.ElideRight
                                        width: parent.width - 60
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Rectangle {
                                visible: root.activeWallpaper === modelData.path
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: 22
                                height: 22
                                radius: 11
                                color: Components.Theme.accentSecondary

                                Text {
                                    text: "✔"
                                    color: Components.Theme.bg
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }

                            MouseArea {
                                id: cardHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "set", modelData.path])
                                    root.activeWallpaper = modelData.path
                                }
                            }
                        }
                    }
                }
            }

            // TAB 2: Effects & FX Customizer (Add, Remove & Tune Effects)
            Flickable {
                visible: root.selectedTab === 2
                anchors.top: divider.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                contentHeight: effectsCol.height + 20
                clip: true

                Column {
                    id: effectsCol
                    width: parent.width
                    spacing: 12

                    // Card 1: Floating Particles
                    Rectangle {
                        width: parent.width
                        height: 120
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Row {
                                width: parent.width
                                Item {
                                    width: parent.width - 80
                                    height: 24
                                    Text { text: "Floating Ambient Particles"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }
                                    Text { text: "Procedural glowing particle canvas layered over the wallpaper"; color: Components.Theme.fgMuted; font.pixelSize: 10; anchors.bottom: parent.bottom }
                                }

                                // Toggle Switch
                                Rectangle {
                                    width: 44
                                    height: 22
                                    radius: 11
                                    color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.enabled) ? Components.Theme.accent : Components.Theme.bgAlt
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.enabled) ? 24 : 2
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let cur = root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.enabled;
                                            root.setEffectValue("particles.enabled", !cur);
                                        }
                                    }
                                }
                            }

                            // Style & Density Selectors
                            Row {
                                spacing: 14
                                Text { text: "Style:"; color: Components.Theme.accent; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }

                                Repeater {
                                    model: ["embers", "dust", "nodes"]
                                    delegate: Rectangle {
                                        width: 68
                                        height: 24
                                        radius: 6
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.style === modelData) ? Components.Theme.accent : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.style === modelData) ? Components.Theme.accent : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: modelData.toUpperCase()
                                            color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.style === modelData) ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setEffectValue("particles.style", modelData)
                                        }
                                    }
                                }

                                Rectangle { width: 1; height: 18; color: Components.Theme.surfaceHover; anchors.verticalCenter: parent.verticalCenter }

                                Text { text: "Density:"; color: Components.Theme.accent; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }

                                Repeater {
                                    model: [20, 40, 80, 120]
                                    delegate: Rectangle {
                                        width: 36
                                        height: 24
                                        radius: 6
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.count === modelData) ? Components.Theme.accentSecondary : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.count === modelData) ? Components.Theme.accentSecondary : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: modelData
                                            color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.particles && root.engineConfig.effects.particles.count === modelData) ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setEffectValue("particles.count", modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Card 2: Interactive Mouse Parallax
                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Column {
                                width: parent.width - 240
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text { text: "Interactive Mouse Parallax"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }
                                Text { text: "Hardware depth offset tilting wallpaper with global cursor movement"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Repeater {
                                    model: [
                                        { name: "Subtle", val: 1.5 },
                                        { name: "Normal", val: 2.5 },
                                        { name: "Dynamic", val: 4.0 }
                                    ]
                                    delegate: Rectangle {
                                        width: 58
                                        height: 24
                                        radius: 6
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.parallax && root.engineConfig.effects.parallax.depth === modelData.val) ? Components.Theme.accentTertiary : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.parallax && root.engineConfig.effects.parallax.depth === modelData.val) ? Components.Theme.accentTertiary : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: modelData.name
                                            color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.parallax && root.engineConfig.effects.parallax.depth === modelData.val) ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setEffectValue("parallax.depth", modelData.val)
                                        }
                                    }
                                }
                            }

                            // Toggle Switch
                            Rectangle {
                                width: 44
                                height: 22
                                radius: 11
                                color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.parallax && root.engineConfig.effects.parallax.enabled) ? Components.Theme.accentTertiary : Components.Theme.bgAlt
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.parallax && root.engineConfig.effects.parallax.enabled) ? 24 : 2
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let cur = root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.parallax && root.engineConfig.effects.parallax.enabled;
                                        root.setEffectValue("parallax.enabled", !cur);
                                    }
                                }
                            }
                        }
                    }

                    // Card 3: Time-of-Day Atmospheric Lighting
                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Column {
                                width: parent.width - 320
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text { text: "Time-of-Day Lighting"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }
                                Text { text: "Atmospheric solar color overlay matching real-world time"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Repeater {
                                    model: ["auto", "dawn", "day", "sunset", "night"]
                                    delegate: Rectangle {
                                        width: 50
                                        height: 24
                                        radius: 6
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.time_lighting && (root.engineConfig.effects.time_lighting.preset === modelData || (modelData === "auto" && root.engineConfig.effects.time_lighting.mode === "auto"))) ? Components.Theme.warning : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.time_lighting && (root.engineConfig.effects.time_lighting.preset === modelData || (modelData === "auto" && root.engineConfig.effects.time_lighting.mode === "auto"))) ? Components.Theme.warning : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: modelData.toUpperCase()
                                            color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.time_lighting && (root.engineConfig.effects.time_lighting.preset === modelData || (modelData === "auto" && root.engineConfig.effects.time_lighting.mode === "auto"))) ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 8
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData === "auto") {
                                                    root.setEffectValue("time_lighting.mode", "auto");
                                                } else {
                                                    root.setEffectValue("time_lighting.mode", "manual");
                                                    root.setEffectValue("time_lighting.preset", modelData);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Toggle Switch
                            Rectangle {
                                width: 44
                                height: 22
                                radius: 11
                                color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.time_lighting && root.engineConfig.effects.time_lighting.enabled) ? Components.Theme.warning : Components.Theme.bgAlt
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.time_lighting && root.engineConfig.effects.time_lighting.enabled) ? 24 : 2
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let cur = root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.time_lighting && root.engineConfig.effects.time_lighting.enabled;
                                        root.setEffectValue("time_lighting.enabled", !cur);
                                    }
                                }
                            }
                        }
                    }

                    // Card 4: Atmospheric Weather Overlay
                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Column {
                                width: parent.width - 200
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text { text: "Weather Canvas Overlay"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }
                                Text { text: "Live animated rain or snow particle physics on desktop"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Repeater {
                                    model: [
                                        { id: "rain", label: "🌧 Rain" },
                                        { id: "snow", label: "❄ Snow" }
                                    ]
                                    delegate: Rectangle {
                                        width: 64
                                        height: 24
                                        radius: 6
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.weather && root.engineConfig.effects.weather.type === modelData.id) ? Components.Theme.accent : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.weather && root.engineConfig.effects.weather.type === modelData.id) ? Components.Theme.accent : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: modelData.label
                                            color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.weather && root.engineConfig.effects.weather.type === modelData.id) ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setEffectValue("weather.type", modelData.id)
                                        }
                                    }
                                }
                            }

                            // Toggle Switch
                            Rectangle {
                                width: 44
                                height: 22
                                radius: 11
                                color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.weather && root.engineConfig.effects.weather.enabled) ? Components.Theme.accent : Components.Theme.bgAlt
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.weather && root.engineConfig.effects.weather.enabled) ? 24 : 2
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let cur = root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.weather && root.engineConfig.effects.weather.enabled;
                                        root.setEffectValue("weather.enabled", !cur);
                                    }
                                }
                            }
                        }
                    }

                    // Card 5: Cyber HUD Clock & Date
                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Column {
                                width: parent.width - 240
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text { text: "Cyber HUD Clock & Date"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }
                                Text { text: "Neon heads-up display showing live time, date, and telemetry"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Repeater {
                                    model: [
                                        { id: "top-right", label: "Top Right" },
                                        { id: "top-left", label: "Top Left" },
                                        { id: "center", label: "Center" }
                                    ]
                                    delegate: Rectangle {
                                        width: 60
                                        height: 24
                                        radius: 6
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.clock_hud && root.engineConfig.effects.clock_hud.position === modelData.id) ? Components.Theme.accentSecondary : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.clock_hud && root.engineConfig.effects.clock_hud.position === modelData.id) ? Components.Theme.accentSecondary : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: modelData.label
                                            color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.clock_hud && root.engineConfig.effects.clock_hud.position === modelData.id) ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 8
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setEffectValue("clock_hud.position", modelData.id)
                                        }
                                    }
                                }
                            }

                            // Toggle Switch
                            Rectangle {
                                width: 44
                                height: 22
                                radius: 11
                                color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.clock_hud && root.engineConfig.effects.clock_hud.enabled) ? Components.Theme.accentSecondary : Components.Theme.bgAlt
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.clock_hud && root.engineConfig.effects.clock_hud.enabled) ? 24 : 2
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let cur = root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.clock_hud && root.engineConfig.effects.clock_hud.enabled;
                                        root.setEffectValue("clock_hud.enabled", !cur);
                                    }
                                }
                            }
                        }
                    }

                    // Card 6: Post-Processing Filters (Scanlines, Vignette, Blur)
                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Column {
                                width: parent.width - 240
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text { text: "Scanlines, Vignette & Depth Blur"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }
                                Text { text: "Atmospheric CRT phosphor lines, edge shading, and hardware blur"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    width: 72
                                    height: 26
                                    radius: 6
                                    color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.scanlines && root.engineConfig.effects.scanlines.enabled) ? Components.Theme.accent : Components.Theme.surface
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Text {
                                        text: "Scanlines"
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.scanlines && root.engineConfig.effects.scanlines.enabled) ? Components.Theme.bg : Components.Theme.fg
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let cur = root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.scanlines && root.engineConfig.effects.scanlines.enabled;
                                            root.setEffectValue("scanlines.enabled", !cur);
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 72
                                    height: 26
                                    radius: 6
                                    color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.vignette && root.engineConfig.effects.vignette.enabled) ? Components.Theme.accentSecondary : Components.Theme.surface
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Text {
                                        text: "Vignette"
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.vignette && root.engineConfig.effects.vignette.enabled) ? Components.Theme.bg : Components.Theme.fg
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let cur = root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.vignette && root.engineConfig.effects.vignette.enabled;
                                            root.setEffectValue("vignette.enabled", !cur);
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 64
                                    height: 26
                                    radius: 6
                                    color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.blur && root.engineConfig.effects.blur.enabled) ? Components.Theme.success : Components.Theme.surface
                                    border.color: Components.Theme.border
                                    border.width: 1

                                    Text {
                                        text: "Blur"
                                        color: (root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.blur && root.engineConfig.effects.blur.enabled) ? Components.Theme.bg : Components.Theme.fg
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let cur = root.engineConfig && root.engineConfig.effects && root.engineConfig.effects.blur && root.engineConfig.effects.blur.enabled;
                                            root.setEffectValue("blur.enabled", !cur);
                                            if (!cur) root.setEffectValue("blur.radius", 5);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Card 7: Visual Display & Color Tuning
                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Column {
                                width: parent.width - 340
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text { text: "Brightness & Contrast Tuning"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }
                                Text { text: "Fine-tune wallpaper luminance, contrast, and color vibrancy"; color: Components.Theme.fgMuted; font.pixelSize: 10 }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Text { text: "Bright:"; color: Components.Theme.warning; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }

                                Repeater {
                                    model: [75, 100, 125]
                                    delegate: Rectangle {
                                        width: 44
                                        height: 24
                                        radius: 6
                                        color: (root.engineConfig && root.engineConfig.effects && (root.engineConfig.effects.brightness || 100) === modelData) ? Components.Theme.warning : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.effects && (root.engineConfig.effects.brightness || 100) === modelData) ? Components.Theme.warning : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: modelData + "%"
                                            color: (root.engineConfig && root.engineConfig.effects && (root.engineConfig.effects.brightness || 100) === modelData) ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 8
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setEffectValue("brightness", modelData)
                                        }
                                    }
                                }

                                Rectangle { width: 1; height: 18; color: Components.Theme.surfaceHover; anchors.verticalCenter: parent.verticalCenter }

                                Text { text: "Contrast:"; color: Components.Theme.accentTertiary; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }

                                Repeater {
                                    model: [80, 100, 120]
                                    delegate: Rectangle {
                                        width: 44
                                        height: 24
                                        radius: 6
                                        color: (root.engineConfig && root.engineConfig.effects && (root.engineConfig.effects.contrast || 100) === modelData) ? Components.Theme.accentTertiary : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.effects && (root.engineConfig.effects.contrast || 100) === modelData) ? Components.Theme.accentTertiary : Components.Theme.border
                                        border.width: 1

                                        Text {
                                            text: modelData + "%"
                                            color: (root.engineConfig && root.engineConfig.effects && (root.engineConfig.effects.contrast || 100) === modelData) ? Components.Theme.bg : Components.Theme.fg
                                            font.pixelSize: 8
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setEffectValue("contrast", modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // TAB 3: Performance & Engine Telemetry
            Flickable {
                visible: root.selectedTab === 3
                anchors.top: divider.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                contentHeight: perfCol.height + 20
                clip: true

                Column {
                    id: perfCol
                    width: parent.width
                    spacing: 14

                    // Profile Selection
                    Rectangle {
                        width: parent.width
                        height: 90
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text { text: "Performance Profiles"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }

                            Row {
                                spacing: 10
                                width: parent.width

                                Repeater {
                                    model: [
                                        { id: "battery_saver", title: "Battery Saver", desc: "30 FPS // Minimal FX", color: Components.Theme.success },
                                        { id: "balanced", title: "Balanced", desc: "60 FPS // Standard FX", color: Components.Theme.accent },
                                        { id: "performance", title: "Performance", desc: "120+ FPS // Max FX", color: Components.Theme.accentSecondary }
                                    ]
                                    delegate: Rectangle {
                                        width: (perfCol.width - 44) / 3
                                        height: 44
                                        radius: 8
                                        color: (root.engineConfig && root.engineConfig.quality === modelData.id) ? Components.Theme.bgAlt : Components.Theme.surface
                                        border.color: (root.engineConfig && root.engineConfig.quality === modelData.id) ? modelData.color : Components.Theme.border
                                        border.width: (root.engineConfig && root.engineConfig.quality === modelData.id) ? 2 : 1

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2
                                            Text {
                                                text: modelData.title
                                                color: (root.engineConfig && root.engineConfig.quality === modelData.id) ? modelData.color : Components.Theme.fg
                                                font.pixelSize: 11
                                                font.bold: true
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                            Text {
                                                text: modelData.desc
                                                color: Components.Theme.fgMuted
                                                font.pixelSize: 9
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.setEffectValue("quality", modelData.id);
                                                if (modelData.id === "battery_saver") {
                                                    root.setEffectValue("fps", 30);
                                                    root.setEffectValue("particles.count", 20);
                                                } else if (modelData.id === "balanced") {
                                                    root.setEffectValue("fps", 60);
                                                    root.setEffectValue("particles.count", 40);
                                                } else {
                                                    root.setEffectValue("fps", 120);
                                                    root.setEffectValue("particles.count", 80);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Smart Automation & Toggles
                    Rectangle {
                        width: parent.width
                        height: 100
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Row {
                                width: parent.width
                                Item {
                                    width: parent.width - 60
                                    height: 20
                                    Text { text: "Intelligent Fullscreen Pause"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "Automatically halts rendering when a fullscreen game or video covers the monitor"; color: Components.Theme.fgMuted; font.pixelSize: 10; anchors.bottom: parent.bottom }
                                }

                                Rectangle {
                                    width: 44
                                    height: 22
                                    radius: 11
                                    color: (root.engineConfig && root.engineConfig.pause_fullscreen) ? Components.Theme.accent : Components.Theme.bgAlt
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: (root.engineConfig && root.engineConfig.pause_fullscreen) ? 24 : 2
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let cur = root.engineConfig && root.engineConfig.pause_fullscreen;
                                            root.setEffectValue("pause_fullscreen", !cur);
                                        }
                                    }
                                }
                            }

                            Rectangle { width: parent.width; height: 1; color: Components.Theme.bgAlt }

                            Row {
                                width: parent.width
                                Item {
                                    width: parent.width - 60
                                    height: 20
                                    Text { text: "Laptop Battery Throttle"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "Reduces FPS and complex effects automatically when unplugged from AC power"; color: Components.Theme.fgMuted; font.pixelSize: 10; anchors.bottom: parent.bottom }
                                }

                                Rectangle {
                                    width: 44
                                    height: 22
                                    radius: 11
                                    color: (root.engineConfig && root.engineConfig.battery_saver) ? Components.Theme.success : Components.Theme.bgAlt
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: (root.engineConfig && root.engineConfig.battery_saver) ? 24 : 2
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let cur = root.engineConfig && root.engineConfig.battery_saver;
                                            root.setEffectValue("battery_saver", !cur);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Engine Telemetry Card & Action Buttons
                    Rectangle {
                        width: parent.width
                        height: 100
                        radius: 12
                        color: Components.Theme.bg
                        border.color: Components.Theme.surfaceHover
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16

                            Column {
                                width: parent.width - 320
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text { text: "Engine Process & Monitors"; color: Components.Theme.fg; font.bold: true; font.pixelSize: 13 }
                                Text {
                                    text: "PID: " + (root.engineStatus ? root.engineStatus.pid : "--") + "  |  Monitors: " + (root.engineStatus && root.engineStatus.monitors ? root.engineStatus.monitors.join(", ") : "None")
                                    color: Components.Theme.accent
                                    font.pixelSize: 11
                                }
                                Text {
                                    text: "Target: " + (root.engineStatus ? root.engineStatus.active : "None")
                                    color: Components.Theme.fgMuted
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                // Reload Webview
                                Rectangle {
                                    width: 90
                                    height: 34
                                    radius: 8
                                    color: reloadHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                                    border.color: reloadHover.containsMouse ? Components.Theme.accent : Components.Theme.border
                                    border.width: 1

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { text: "󰑐"; color: Components.Theme.accent; font.pixelSize: 12 }
                                        Text { text: "Reload"; color: Components.Theme.fg; font.pixelSize: 11; font.bold: true }
                                    }

                                    MouseArea {
                                        id: reloadHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "reload"]);
                                        }
                                    }
                                }

                                // Restart Engine
                                Rectangle {
                                    width: 95
                                    height: 34
                                    radius: 8
                                    color: restartHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                                    border.color: restartHover.containsMouse ? Components.Theme.accentSecondary : Components.Theme.border
                                    border.width: 1

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { text: "󰜉"; color: Components.Theme.accentSecondary; font.pixelSize: 12 }
                                        Text { text: "Restart"; color: Components.Theme.fg; font.pixelSize: 11; font.bold: true }
                                    }

                                    MouseArea {
                                        id: restartHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "restart"]);
                                            refreshConfigTimer.running = true;
                                        }
                                    }
                                }

                                // Random Wallpaper
                                Rectangle {
                                    width: 95
                                    height: 34
                                    radius: 8
                                    color: randHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                                    border.color: randHover.containsMouse ? Components.Theme.success : Components.Theme.border
                                    border.width: 1

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { text: "󰒝"; color: Components.Theme.success; font.pixelSize: 12 }
                                        Text { text: "Random"; color: Components.Theme.fg; font.pixelSize: 11; font.bold: true }
                                    }

                                    MouseArea {
                                        id: randHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "random"]);
                                            refreshConfigTimer.running = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // TAB 4: Canvas Colors
            Flickable {
                visible: root.selectedTab === 4
                anchors.top: divider.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                contentHeight: colorGrid.height
                clip: true

                Grid {
                    id: colorGrid
                    columns: 4
                    spacing: 14
                    width: parent.width

                    Repeater {
                        model: root.canvasColors

                        delegate: Rectangle {
                            width: (colorGrid.width - (colorGrid.spacing * 3)) / 4
                            height: 100
                            radius: 12
                            color: modelData.hex
                            border.color: root.activeWallpaper === ("color:" + modelData.hex) ? Components.Theme.accent : (colorHover.containsMouse ? Components.Theme.accentSecondary : Components.Theme.border)
                            border.width: root.activeWallpaper === ("color:" + modelData.hex) ? 2 : 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: modelData.name
                                    color: Components.Theme.fg
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: modelData.hex
                                    color: Components.Theme.accent
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            // Active checkmark badge
                            Rectangle {
                                visible: root.activeWallpaper === ("color:" + modelData.hex)
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 20
                                height: 20
                                radius: 10
                                color: Components.Theme.accent

                                Text {
                                    text: "✔"
                                    color: Components.Theme.bg
                                    font.pixelSize: 10
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }

                            MouseArea {
                                id: colorHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper-engine/wallpaperctl", "color", modelData.hex])
                                    root.activeWallpaper = "color:" + modelData.hex
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dedicated Wi-Fi Authentication Dialog (Overlay PanelWindow with full keyboard focus)
    PanelWindow {
        id: wifiAuthModalWindow
        visible: root.wifiSelectedSsid !== ""
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.wifiSelectedSsid !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Dark dim backdrop with click-to-dismiss
        Rectangle {
            anchors.fill: parent
            color: "#80000000"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.wifiSelectedSsid = ""
                    pwdInput.text = ""
                }
            }

            // Modal Card
            Rectangle {
                width: 440
                height: 240
                radius: 16
                color: Components.Theme.bg
                border.color: Components.Theme.accent
                border.width: 1.5
                anchors.centerIn: parent

                MouseArea {
                    anchors.fill: parent
                    // Absorb clicks inside card so they don't dismiss the modal
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Row {
                        spacing: 12
                        Text { text: "󰌾"; color: Components.Theme.accent; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            spacing: 2
                            Text { text: "Wi-Fi Authentication"; color: Components.Theme.fg; font.pixelSize: 15; font.bold: true }
                            Text { text: "Enter password for \"" + root.wifiSelectedSsid + "\""; color: Components.Theme.accentTertiary; font.pixelSize: 12; elide: Text.ElideRight; width: 330 }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Components.Theme.surfaceHover }

                    // Password Input Field
                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: 8
                        color: Components.Theme.bg
                        border.color: pwdInput.activeFocus ? Components.Theme.accent : Components.Theme.border
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Item {
                                width: parent.width - 32
                                height: parent.height

                                TextInput {
                                    id: pwdInput
                                    anchors.fill: parent
                                    color: Components.Theme.fg
                                    font.pixelSize: 14
                                    echoMode: showPwd.checked ? TextInput.Normal : TextInput.Password
                                    clip: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    focus: true
                                    Keys.onEscapePressed: {
                                        root.wifiSelectedSsid = ""
                                        pwdInput.text = ""
                                    }
                                    onAccepted: {
                                        if (text.trim() !== "") {
                                            Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "connect", root.wifiSelectedSsid, text.trim()])
                                            root.wifiSelectedSsid = ""
                                            pwdInput.text = ""
                                            wifiRefreshTimer.restart()
                                        }
                                    }
                                }

                                Text {
                                    text: "Enter network password..."
                                    color: Components.Theme.fgMuted
                                    font.pixelSize: 13
                                    visible: pwdInput.text === "" && !pwdInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Eye toggle icon
                            Text {
                                id: showPwd
                                property bool checked: false
                                text: checked ? "󰈈" : "󰈉"
                                color: checked ? Components.Theme.accent : Components.Theme.fgMuted
                                font.pixelSize: 18
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: showPwd.checked = !showPwd.checked
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            z: -1
                            onClicked: pwdInput.forceActiveFocus()
                        }
                    }

                    // Action Buttons Row
                    Row {
                        anchors.right: parent.right
                        spacing: 10

                        // Rofi Prompt button as quick alternative
                        Rectangle {
                            width: 125
                            height: 36
                            radius: 8
                            color: rofiHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                            border.color: Components.Theme.border
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰌾"; color: Components.Theme.accentTertiary; font.pixelSize: 12 }
                                Text { text: "Rofi Prompt"; color: Components.Theme.fg; font.pixelSize: 12 }
                            }

                            MouseArea {
                                id: rofiHover
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let curSsid = root.wifiSelectedSsid
                                    root.wifiSelectedSsid = ""
                                    pwdInput.text = ""
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "connect-rofi", curSsid])
                                    wifiRefreshTimer.restart()
                                }
                            }
                        }

                        // Cancel Button
                        Rectangle {
                            width: 80
                            height: 36
                            radius: 8
                            color: cancelHover.containsMouse ? Components.Theme.bgAlt : Components.Theme.surface
                            border.color: Components.Theme.border
                            border.width: 1

                            Text { text: "Cancel"; color: Components.Theme.fg; font.pixelSize: 13; anchors.centerIn: parent }

                            MouseArea {
                                id: cancelHover
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.wifiSelectedSsid = ""
                                    pwdInput.text = ""
                                }
                            }
                        }

                        // Connect Button
                        Rectangle {
                            width: 95
                            height: 36
                            radius: 8
                            color: connHover.containsMouse ? Components.Theme.accent : Components.Theme.accent

                            Text { text: "Connect"; color: Components.Theme.bg; font.pixelSize: 13; font.bold: true; anchors.centerIn: parent }

                            MouseArea {
                                id: connHover
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (pwdInput.text.trim() !== "") {
                                        Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wifi.sh", "connect", root.wifiSelectedSsid, pwdInput.text.trim()])
                                        root.wifiSelectedSsid = ""
                                        pwdInput.text = ""
                                        wifiRefreshTimer.restart()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Timer {
            id: focusTimer
            interval: 50
            repeat: false
            onTriggered: pwdInput.forceActiveFocus()
        }

        onVisibleChanged: {
            if (visible) {
                pwdInput.text = ""
                pwdInput.forceActiveFocus()
                focusTimer.restart()
            } else {
                pwdInput.text = ""
            }
        }
    }
}
