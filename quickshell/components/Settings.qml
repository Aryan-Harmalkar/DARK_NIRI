import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    implicitWidth: btnRow.width
    implicitHeight: 32

    property bool isSettingsOpen: false
    property bool isGalleryOpen: false
    property bool isWifiOpen: false
    property bool isBtOpen: false
    property bool isNotifOpen: false

    property var wallpapers: []
    property string activeWallpaper: ""
    property int selectedTab: 0 // 0: Static, 1: Animated/Live, 2: Canvas Colors

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
        { name: "Tokyo Night", hex: "#1a1b26" },
        { name: "Pure Black", hex: "#0c0d14" },
        { name: "Midnight Blue", hex: "#0f141c" },
        { name: "Cyber Purple", hex: "#1f1a30" },
        { name: "Nord Dark", hex: "#2e3440" },
        { name: "Catppuccin Mocha", hex: "#1e1e2e" },
        { name: "Slate Charcoal", hex: "#24283b" },
        { name: "Emerald Night", hex: "#112218" }
    ]

    function getFilteredWallpapers() {
        if (!root.wallpapers) return [];
        if (root.selectedTab === 0) {
            return root.wallpapers.filter(w => w.type === "image");
        } else if (root.selectedTab === 1) {
            return root.wallpapers.filter(w => w.type === "video");
        }
        return [];
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

    // Wallpapers background process
    Process {
        id: listProcess
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper.sh", "list"]
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
        command: [Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper.sh", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeWallpaper = text.trim()
            }
        }
    }

    // Top Bar Right Buttons: Notification Icon on Left, Settings Icon on Right
    Row {
        id: btnRow
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        // 1. Notification Icon Button (Left side of settings)
        Rectangle {
            id: notifBtn
            width: 32
            height: 32
            radius: 16
            color: notifMouse.containsMouse || root.isNotifOpen ? "#24283b" : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: root.notifications.length > 0 ? "󰂚" : "󰂜"
                color: root.isNotifOpen ? "#7aa2f7" : (notifMouse.containsMouse ? "#bb9af7" : "#c0caf5")
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
                color: "#f7768e"
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
                        root.isGalleryOpen = false
                        root.isWifiOpen = false
                        root.isBtOpen = false
                        notifProcess.running = true
                    }
                }
            }
        }

        // 2. Settings Button on Bar
        Rectangle {
            id: btnRect
            width: 32
            height: 32
            radius: 16
            color: btnMouse.containsMouse || root.isSettingsOpen ? "#24283b" : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: "󰒓"
                color: root.isSettingsOpen ? "#7aa2f7" : (btnMouse.containsMouse ? "#bb9af7" : "#c0caf5")
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
        anchor.rect.y: 55
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 600
        visible: root.isSettingsOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#F21a1b26"
            border.color: "#3b4261"
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
                               ? (wifiMouse.containsMouse ? "#344470" : "#283456")
                               : (wifiMouse.containsMouse ? "#24283b" : "#16161e")
                        border.color: root.wifiSsid !== "Disconnected" ? "#7aa2f7" : "#292e42"
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
                                color: root.wifiSsid !== "Disconnected" ? "#7aa2f7" : "#1f2335"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: root.wifiSsid !== "Disconnected" ? "󰤨" : "󰤭"
                                    color: root.wifiSsid !== "Disconnected" ? "#1a1b26" : "#565f89"
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
                                    color: root.wifiSsid !== "Disconnected" ? "#ffffff" : "#c0caf5"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: root.wifiSsid !== "Disconnected" ? (root.wifiSsid + " • Manage") : "Disconnected • Scan"
                                    color: root.wifiSsid !== "Disconnected" ? "#7dcfff" : "#565f89"
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
                               ? (btMouse.containsMouse ? "#274868" : "#1e3852")
                               : (btMouse.containsMouse ? "#24283b" : "#16161e")
                        border.color: root.isBtOn ? "#7dcfff" : "#292e42"
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
                                color: root.isBtOn ? "#7dcfff" : "#1f2335"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: root.isBtOn ? "󰂯" : "󰂲"
                                    color: root.isBtOn ? "#1a1b26" : "#565f89"
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
                                    color: root.isBtOn ? "#ffffff" : "#c0caf5"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: root.btConnectedDeviceName !== ""
                                          ? (root.btConnectedDeviceName + " • Connected")
                                          : (root.isBtOn ? "Enabled • Manage" : "Disabled / Off")
                                    color: root.isBtOn ? "#7dcfff" : "#565f89"
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
                               ? (powerTileMouse.containsMouse ? "#274433" : "#1d3326")
                               : (root.activePowerProfile === "performance"
                                  ? (powerTileMouse.containsMouse ? "#54311c" : "#3d2314")
                                  : (powerTileMouse.containsMouse ? "#2b3c69" : "#1e2a4a"))
                        border.color: root.activePowerProfile === "power-saver"
                                      ? "#9ece6a"
                                      : (root.activePowerProfile === "performance" ? "#ff9e64" : "#7aa2f7")
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
                                       ? "#9ece6a"
                                       : (root.activePowerProfile === "performance" ? "#ff9e64" : "#7aa2f7")
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    text: root.activePowerProfile === "power-saver"
                                          ? "󰌪"
                                          : (root.activePowerProfile === "performance" ? "󰓅" : "󰾆")
                                    color: "#1a1b26"
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
                                            color: root.activePowerProfile === "power-saver" ? "#9ece6a" : "#414868"
                                        }
                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: root.activePowerProfile === "balanced" ? "#7aa2f7" : "#414868"
                                        }
                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: root.activePowerProfile === "performance" ? "#ff9e64" : "#414868"
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
                                           ? "#9ece6a"
                                           : (root.activePowerProfile === "performance" ? "#ff9e64" : "#7dcfff")
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
                               ? (micMouse.containsMouse ? "#632b39" : "#4f232e")
                               : (micMouse.containsMouse ? "#24283b" : "#1f2335")
                        border.color: root.isMicMuted ? "#f7768e" : "#292e42"
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
                                color: root.isMicMuted ? "#f7768e" : "#16161e"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: root.isMicMuted ? "󰍭" : "󰍬"
                                    color: root.isMicMuted ? "#1a1b26" : "#9ece6a"
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
                                    color: root.isMicMuted ? "#ffffff" : "#c0caf5"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: root.isMicMuted ? "Muted (Mic Off)" : "Active / Live"
                                    color: root.isMicMuted ? "#f7768e" : "#9ece6a"
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
                        color: shotMouse.containsMouse ? "#24283b" : "#1f2335"
                        border.color: shotMouse.containsMouse ? "#bb9af7" : "#292e42"
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
                                color: "#16161e"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: "󰹑"
                                    color: "#bb9af7"
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
                                    color: "#c0caf5"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: "Select area capture"
                                    color: "#565f89"
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
                               ? (recTileMouse.containsMouse ? "#6d2938" : "#5c1d29")
                               : (recTileMouse.containsMouse ? "#24283b" : "#1f2335")
                        border.color: root.recordStatus !== "idle" ? "#f7768e" : "#292e42"
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
                                color: root.recordStatus !== "idle" ? "#f7768e" : "#16161e"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: "󰻃"
                                    color: root.recordStatus !== "idle" ? "#1a1b26" : "#f7768e"
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
                                    color: root.recordStatus !== "idle" ? "#ffffff" : "#c0caf5"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: root.recordStatus !== "idle" ? "Recording Active!" : "Select region to record"
                                    color: root.recordStatus !== "idle" ? "#f7768e" : "#565f89"
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

                // Wallpaper & Canvas Setter Banner (Full width)
                Rectangle {
                    width: parent.width
                    height: 52
                    radius: 12
                    color: wallTileMouse.containsMouse ? "#24283b" : "#1f2335"
                    border.color: wallTileMouse.containsMouse ? "#7aa2f7" : "#292e42"
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
                            color: "#16161e"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "󰸉"
                                color: "#7aa2f7"
                                font.pixelSize: 20
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 38 - 14 - 30

                            Text {
                                text: "Wallpapers & Canvas"
                                color: "#c0caf5"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: "Live Video & Backdrops Gallery"
                                color: "#565f89"
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            text: "󰅂"
                            color: wallTileMouse.containsMouse ? "#7aa2f7" : "#565f89"
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
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#24283b"
                }

                // 2. Interactive Brightness Slider (Before Volume)
                Item {
                    width: parent.width
                    height: 44

                    Text {
                        id: brightIcon
                        text: "󰃠"
                        color: "#e0af68"
                        font.pixelSize: 24
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: brightVal
                        text: root.brightnessLevel + "%"
                        color: "#e0af68"
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
                        color: "#16161e"

                        Rectangle {
                            width: parent.width * (root.brightnessLevel / 100)
                            height: parent.height
                            radius: 5
                            color: "#e0af68"
                        }

                        // Slider Knob
                        Rectangle {
                            x: Math.min(Math.max(0, parent.width * (root.brightnessLevel / 100) - 10), parent.width - 20)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            radius: 10
                            color: "#e0af68"
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
                        color: root.isAudioMuted ? "#f7768e" : "#7aa2f7"
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
                        color: "#7dcfff"
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
                        color: "#16161e"

                        Rectangle {
                            width: parent.width * (root.volumeLevel / 100)
                            height: parent.height
                            radius: 5
                            color: root.isAudioMuted ? "#565f89" : "#7aa2f7"
                        }

                        // Slider Knob
                        Rectangle {
                            x: Math.min(Math.max(0, parent.width * (root.volumeLevel / 100) - 10), parent.width - 20)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            radius: 10
                            color: root.isAudioMuted ? "#565f89" : "#7aa2f7"
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
                    color: "#24283b"
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
                        color: reloadMouse.containsMouse ? "#24283b" : "#1f2335"
                        border.color: reloadMouse.containsMouse ? "#7dcfff" : "#292e42"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰑐"; color: "#7dcfff"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Refresh Niri"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: reloadMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isSettingsOpen = false
                                Quickshell.execDetached(["sh", "-c", "killall qs; qs -d -p $HOME/DARK_NIRI/quickshell/shell.qml & notify-send 'Niri' 'Bar & Environment Reloaded' -i view-refresh"])
                            }
                        }
                    }

                    // 2. Lock Screen
                    Rectangle {
                        width: (parent.width - 20) / 3
                        height: 44
                        radius: 10
                        color: lockMouse.containsMouse ? "#24283b" : "#1f2335"
                        border.color: lockMouse.containsMouse ? "#7aa2f7" : "#292e42"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰌾"; color: "#7aa2f7"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Lock Screen"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
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
                        color: exitMouse.containsMouse ? "#24283b" : "#1f2335"
                        border.color: exitMouse.containsMouse ? "#bb9af7" : "#292e42"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰍃"; color: "#bb9af7"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Log Out"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
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
                        color: rebootMouse.containsMouse ? "#24283b" : "#1f2335"
                        border.color: rebootMouse.containsMouse ? "#e0af68" : "#292e42"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰜉"; color: "#e0af68"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Restart"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
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
                        color: shutMouse.containsMouse ? "#3d212c" : "#1f2335"
                        border.color: shutMouse.containsMouse ? "#f7768e" : "#292e42"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰐥"; color: "#f7768e"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Shutdown"; color: "#c0caf5"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
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
                        color: sudoShutMouse.containsMouse ? "#f7768e" : "#2e1a24"
                        border.color: "#f7768e"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "󰐦"
                                color: sudoShutMouse.containsMouse ? "#1a1b26" : "#f7768e"
                                font.pixelSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Sudo Off Now"
                                color: sudoShutMouse.containsMouse ? "#1a1b26" : "#f7768e"
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

    // Dedicated Notification Center Modal (Anchored Top-Right, Slide Animation)
    PopupWindow {
        id: notifPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(barWindow.width - 540 - 20)
        anchor.rect.y: 55
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 520
        visible: root.isNotifOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#F51a1b26"
            border.color: "#3b4261"
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

                        Text { text: "󰂚"; color: "#7aa2f7"; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: "Notifications"; color: "#c0caf5"; font.pixelSize: 16; font.bold: true }
                            Text {
                                text: root.notifications.length > 0 ? (root.notifications.length + " alerts in history") : "No new notifications"
                                color: "#565f89"
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
                            color: clearAllMouse.containsMouse ? "#f7768e" : "#1f2335"
                            border.color: clearAllMouse.containsMouse ? "#f7768e" : "#3b4261"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "󰎟"
                                    color: clearAllMouse.containsMouse ? "#1a1b26" : "#f7768e"
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: "Clear All"
                                    color: clearAllMouse.containsMouse ? "#1a1b26" : "#c0caf5"
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
                            color: notifCloseMouse.containsMouse ? "#f7768e" : "#1f2335"
                            border.color: notifCloseMouse.containsMouse ? "#f7768e" : "#3b4261"
                            border.width: 1

                            Text { text: "󰅖"; color: notifCloseMouse.containsMouse ? "#1a1b26" : "#c0caf5"; font.pixelSize: 14; anchors.centerIn: parent }

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
                Rectangle { width: parent.width; height: 1; color: "#24283b" }

                // Empty State View
                Item {
                    visible: root.notifications.length === 0
                    width: parent.width
                    height: 380

                    Column {
                        anchors.centerIn: parent
                        spacing: 12
                        Text { text: "󰂜"; color: "#3b4261"; font.pixelSize: 52; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "No Notifications"; color: "#c0caf5"; font.pixelSize: 15; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "You're all caught up!"; color: "#565f89"; font.pixelSize: 13; anchors.horizontalCenter: parent.horizontalCenter }
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
                                color: itemHover.containsMouse ? "#24283b" : "#16161e"
                                border.color: itemHover.containsMouse ? "#7aa2f7" : "#292e42"
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
                                            color: "#1f2335"
                                            border.color: "#3b4261"
                                            border.width: 1

                                            Text {
                                                id: appTxt
                                                text: modelData.app
                                                color: "#7dcfff"
                                                font.pixelSize: 10
                                                font.bold: true
                                                anchors.centerIn: parent
                                            }
                                        }

                                        Text {
                                            text: modelData.summary
                                            color: "#c0caf5"
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
                                        color: "#9aa5ce"
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
                                    color: delHover.containsMouse ? "#f7768e" : "#1f2335"
                                    border.color: delHover.containsMouse ? "#f7768e" : "#3b4261"
                                    border.width: 1

                                    Text {
                                        text: "󰅖"
                                        color: delHover.containsMouse ? "#1a1b26" : "#565f89"
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
        anchor.rect.y: 55
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 520
        visible: root.isWifiOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#F51a1b26"
            border.color: "#3b4261"
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

                        Text { text: "󰤨"; color: "#7aa2f7"; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: "Wi-Fi Networks"; color: "#c0caf5"; font.pixelSize: 16; font.bold: true }
                            Text { text: "Manage & connect to wireless networks"; color: "#565f89"; font.pixelSize: 12 }
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
                            color: root.wifiEnabled ? "#7aa2f7" : "#1f2335"
                            border.color: root.wifiEnabled ? "#7aa2f7" : "#3b4261"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: root.wifiEnabled ? "󰤨  Wi-Fi ON" : "󰤭  Wi-Fi OFF"
                                    color: root.wifiEnabled ? "#1a1b26" : "#565f89"
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
                            color: wifiRescanMouse.containsMouse ? "#24283b" : "#1f2335"
                            border.color: wifiRescanMouse.containsMouse ? "#7aa2f7" : "#3b4261"
                            border.width: 1

                            Text { text: "󰑐"; color: wifiRescanMouse.containsMouse ? "#7aa2f7" : "#c0caf5"; font.pixelSize: 14; anchors.centerIn: parent }

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
                            color: wifiCloseMouse.containsMouse ? "#f7768e" : "#1f2335"
                            border.color: wifiCloseMouse.containsMouse ? "#f7768e" : "#3b4261"
                            border.width: 1

                            Text { text: "󰅖"; color: wifiCloseMouse.containsMouse ? "#1a1b26" : "#c0caf5"; font.pixelSize: 14; anchors.centerIn: parent }

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
                Rectangle { width: parent.width; height: 1; color: "#24283b" }

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
                                       ? "#253456"
                                       : (netHover.containsMouse ? "#24283b" : "#16161e")
                                border.color: modelData.connected ? "#7aa2f7" : "#292e42"
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
                                        color: modelData.connected ? "#7dcfff" : "#7aa2f7"
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
                                                color: modelData.connected ? "#ffffff" : "#c0caf5"
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
                                                color: "#1f2335"
                                                border.color: "#3b4261"
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    id: bandText
                                                    text: modelData.band || "2.4 GHz"
                                                    color: "#7aa2f7"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    anchors.centerIn: parent
                                                }
                                            }

                                            // Security badge
                                            Text {
                                                visible: modelData.security !== "Open"
                                                text: "󰌾 " + modelData.security
                                                color: "#565f89"
                                                font.pixelSize: 11
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            // WPS ON Badge
                                            Rectangle {
                                                visible: modelData.wps
                                                width: 68
                                                height: 18
                                                radius: 4
                                                color: "#1d3326"
                                                border.color: "#9ece6a"
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    text: "󰖩 WPS ON"
                                                    color: "#9ece6a"
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
                                            color: modelData.connected ? "#7dcfff" : (modelData.wps ? "#9ece6a" : "#565f89")
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
                                        color: disMouse.containsMouse ? "#f7768e" : "#1f2335"
                                        border.color: "#f7768e"
                                        border.width: 1

                                        Text {
                                            text: "Disconnect"
                                            color: disMouse.containsMouse ? "#1a1b26" : "#f7768e"
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
                                        color: forMouse.containsMouse ? "#f7768e" : "#1f2335"
                                        border.color: forMouse.containsMouse ? "#f7768e" : "#3b4261"
                                        border.width: 1

                                        Text {
                                            text: "Forget"
                                            color: forMouse.containsMouse ? "#1a1b26" : "#565f89"
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
                                        color: connMouse.containsMouse ? (modelData.wps ? "#9ece6a" : "#7aa2f7") : "#1f2335"
                                        border.color: modelData.wps ? "#9ece6a" : "#7aa2f7"
                                        border.width: 1

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                visible: modelData.wps
                                                text: "󰖩"
                                                color: connMouse.containsMouse ? "#1a1b26" : "#9ece6a"
                                                font.pixelSize: 11
                                            }
                                            Text {
                                                text: "Connect"
                                                color: connMouse.containsMouse ? "#1a1b26" : (modelData.wps ? "#9ece6a" : "#7aa2f7")
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
        anchor.rect.y: 55
        anchor.rect.width: 540
        anchor.rect.height: 1

        implicitWidth: 540
        implicitHeight: 520
        visible: root.isBtOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#F51a1b26"
            border.color: "#3b4261"
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

                        Text { text: "󰂯"; color: "#7dcfff"; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: "Bluetooth Devices"; color: "#c0caf5"; font.pixelSize: 16; font.bold: true }
                            Text { text: "Pair, connect, and audio profiles"; color: "#565f89"; font.pixelSize: 12 }
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
                            color: root.isBtOn ? "#7dcfff" : "#1f2335"
                            border.color: root.isBtOn ? "#7dcfff" : "#3b4261"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: root.isBtOn ? "󰂯  BT ON" : "󰂲  BT OFF"
                                    color: root.isBtOn ? "#1a1b26" : "#565f89"
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
                            color: btScanMouse.containsMouse ? "#24283b" : "#1f2335"
                            border.color: btScanMouse.containsMouse ? "#7dcfff" : "#3b4261"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text { text: "󰑐"; color: "#7dcfff"; font.pixelSize: 13 }
                                Text { text: "Scan"; color: "#c0caf5"; font.pixelSize: 11; font.bold: true }
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
                            color: btCloseMouse.containsMouse ? "#f7768e" : "#1f2335"
                            border.color: btCloseMouse.containsMouse ? "#f7768e" : "#3b4261"
                            border.width: 1

                            Text { text: "󰅖"; color: btCloseMouse.containsMouse ? "#1a1b26" : "#c0caf5"; font.pixelSize: 14; anchors.centerIn: parent }

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
                Rectangle { width: parent.width; height: 1; color: "#24283b" }

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
                                       ? "#1e3852"
                                       : (btDevHover.containsMouse ? "#24283b" : "#16161e")
                                border.color: modelData.connected ? "#7dcfff" : "#292e42"
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
                                                color: modelData.connected ? "#7dcfff" : "#7aa2f7"
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
                                                        color: modelData.connected ? "#ffffff" : "#c0caf5"
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                    }

                                                    // Battery Badge
                                                    Rectangle {
                                                        visible: modelData.battery !== null
                                                        width: 48
                                                        height: 16
                                                        radius: 4
                                                        color: "#1f3a2c"
                                                        border.color: "#9ece6a"
                                                        border.width: 1
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        Text {
                                                            text: "󰥉 " + (modelData.battery || 100) + "%"
                                                            color: "#9ece6a"
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
                                                    color: modelData.connected ? "#7dcfff" : "#565f89"
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
                                                color: btDisMouse.containsMouse ? "#f7768e" : "#1f2335"
                                                border.color: "#f7768e"
                                                border.width: 1

                                                Text {
                                                    text: "Disconnect"
                                                    color: btDisMouse.containsMouse ? "#1a1b26" : "#f7768e"
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
                                                color: btConnMouse.containsMouse ? "#7dcfff" : "#1f2335"
                                                border.color: "#7dcfff"
                                                border.width: 1

                                                Text {
                                                    text: "Connect"
                                                    color: btConnMouse.containsMouse ? "#1a1b26" : "#7dcfff"
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
                                                color: btPairMouse.containsMouse ? "#7aa2f7" : "#1f2335"
                                                border.color: "#7aa2f7"
                                                border.width: 1

                                                Text {
                                                    text: "Pair"
                                                    color: btPairMouse.containsMouse ? "#1a1b26" : "#7aa2f7"
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
                                                color: btForMouse.containsMouse ? "#f7768e" : "#1f2335"
                                                border.color: btForMouse.containsMouse ? "#f7768e" : "#3b4261"
                                                border.width: 1

                                                Text {
                                                    text: "Forget"
                                                    color: btForMouse.containsMouse ? "#1a1b26" : "#565f89"
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
                                            color: "#565f89"
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
                                                       ? "#7dcfff"
                                                       : (profMouse.containsMouse ? "#24283b" : "#16161e")
                                                border.color: modelData.id === modelData.active_profile ? "#7dcfff" : "#3b4261"
                                                border.width: 1

                                                Text {
                                                    id: profText
                                                    text: modelData.name
                                                    color: (modelData.id === modelData.active_profile || (modelData.active_profile && modelData.active_profile.indexOf(modelData.id) !== -1))
                                                           ? "#1a1b26"
                                                           : "#c0caf5"
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

    // Dedicated Wallpaper & Canvas Setter Modal (Anchored Top-Right, Slide Animation)
    PopupWindow {
        id: galleryPopup
        anchor.window: barWindow
        anchor.rect.x: Math.round(barWindow.width - 720 - 20)
        anchor.rect.y: 55
        anchor.rect.width: 720
        anchor.rect.height: 1

        implicitWidth: 720
        implicitHeight: 520
        visible: root.isGalleryOpen
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#F51a1b26"
            border.color: "#3b4261"
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

                    Text {
                        text: "󰸉"
                        color: "#7aa2f7"
                        font.pixelSize: 22
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "Wallpaper & Backdrop Setter"
                            color: "#c0caf5"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            text: "Custom backgrounds for your Niri workspace"
                            color: "#565f89"
                            font.pixelSize: 11
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // Refresh Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: refreshHover.containsMouse ? "#24283b" : "#1f2335"
                        border.color: refreshHover.containsMouse ? "#7aa2f7" : "#3b4261"
                        border.width: 1

                        Text {
                            text: "󰑐"
                            color: refreshHover.containsMouse ? "#7aa2f7" : "#c0caf5"
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
                            }
                        }
                    }

                    // Close Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: closeHover.containsMouse ? "#f7768e" : "#1f2335"
                        border.color: closeHover.containsMouse ? "#f7768e" : "#3b4261"
                        border.width: 1

                        Text {
                            text: "󰅖"
                            color: closeHover.containsMouse ? "#1a1b26" : "#c0caf5"
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

            // Category Tab Bar
            Rectangle {
                id: tabBar
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 40
                radius: 10
                color: "#16161e"
                border.color: "#292e42"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 6

                    // Tab 0: Static Pictures
                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: parent.height
                        radius: 7
                        color: root.selectedTab === 0 ? "#24283b" : "transparent"
                        border.color: root.selectedTab === 0 ? "#7aa2f7" : "transparent"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰸉"; color: root.selectedTab === 0 ? "#7aa2f7" : "#565f89"; font.pixelSize: 14 }
                            Text { text: "Static Pictures"; color: root.selectedTab === 0 ? "#c0caf5" : "#565f89"; font.pixelSize: 12; font.bold: root.selectedTab === 0 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = 0
                        }
                    }

                    // Tab 1: Live / Animated
                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: parent.height
                        radius: 7
                        color: root.selectedTab === 1 ? "#24283b" : "transparent"
                        border.color: root.selectedTab === 1 ? "#f7768e" : "transparent"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰐊"; color: root.selectedTab === 1 ? "#f7768e" : "#565f89"; font.pixelSize: 14 }
                            Text { text: "Live / Animated"; color: root.selectedTab === 1 ? "#c0caf5" : "#565f89"; font.pixelSize: 12; font.bold: root.selectedTab === 1 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = 1
                        }
                    }

                    // Tab 2: Canvas Colors
                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: parent.height
                        radius: 7
                        color: root.selectedTab === 2 ? "#24283b" : "transparent"
                        border.color: root.selectedTab === 2 ? "#9ece6a" : "transparent"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰏘"; color: root.selectedTab === 2 ? "#9ece6a" : "#565f89"; font.pixelSize: 14 }
                            Text { text: "Canvas Colors"; color: root.selectedTab === 2 ? "#c0caf5" : "#565f89"; font.pixelSize: 12; font.bold: root.selectedTab === 2 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = 2
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                id: divider
                anchors.top: tabBar.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 1
                color: "#292e42"
            }

            // Tab 0 & 1: Wallpaper Grid (Pictures & Animated Videos)
            Flickable {
                visible: root.selectedTab !== 2
                anchors.top: divider.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                contentHeight: grid.height
                clip: true

                Grid {
                    id: grid
                    columns: 3
                    spacing: 14
                    width: parent.width

                    Repeater {
                        model: root.isGalleryOpen ? root.getFilteredWallpapers() : []

                        delegate: Rectangle {
                            id: card
                            width: (grid.width - (grid.spacing * (grid.columns - 1))) / grid.columns
                            height: 150
                            radius: 12
                            color: "#16161e"
                            clip: true
                            border.color: root.activeWallpaper === modelData.path ? "#7aa2f7" : (cardHover.containsMouse ? "#bb9af7" : "#292e42")
                            border.width: root.activeWallpaper === modelData.path ? 2 : 1

                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + (modelData.thumb ? modelData.thumb : modelData.path)
                                sourceSize.width: 320
                                sourceSize.height: 200
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            // Dynamic Video / Animation Badge
                            Rectangle {
                                visible: modelData.type === "video"
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 8
                                width: 24
                                height: 24
                                radius: 12
                                color: "#CC16161e"
                                border.color: "#7aa2f7"
                                border.width: 1

                                Text {
                                    text: "󰐊"
                                    color: "#7aa2f7"
                                    font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                            }

                            // Dark gradient overlay at bottom for text readability
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 36
                                color: "#CC16161e"

                                Text {
                                    text: modelData.name
                                    color: root.activeWallpaper === modelData.path ? "#7aa2f7" : "#c0caf5"
                                    font.pixelSize: 11
                                    font.bold: root.activeWallpaper === modelData.path
                                    elide: Text.ElideMiddle
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            // Active checkmark badge
                            Rectangle {
                                visible: root.activeWallpaper === modelData.path
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: 24
                                height: 24
                                radius: 12
                                color: "#7aa2f7"

                                Text {
                                    text: "✔"
                                    color: "#1a1b26"
                                    font.pixelSize: 12
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
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper.sh", "set", modelData.path])
                                    root.activeWallpaper = modelData.path
                                }
                            }
                        }
                    }
                }
            }

            // Tab 2: Canvas / Backdrop Color Selector
            Item {
                visible: root.selectedTab === 2
                anchors.top: divider.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16

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
                            border.color: root.activeWallpaper === ("color:" + modelData.hex) ? "#7aa2f7" : (colorHover.containsMouse ? "#bb9af7" : "#3b4261")
                            border.width: root.activeWallpaper === ("color:" + modelData.hex) ? 2 : 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: modelData.name
                                    color: "#c0caf5"
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: modelData.hex
                                    color: "#7aa2f7"
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
                                color: "#7aa2f7"

                                Text {
                                    text: "✔"
                                    color: "#1a1b26"
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
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/DARK_NIRI/quickshell/wallpaper.sh", "color", modelData.hex])
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
                color: "#1a1b26"
                border.color: "#7aa2f7"
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
                        Text { text: "󰌾"; color: "#7aa2f7"; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            spacing: 2
                            Text { text: "Wi-Fi Authentication"; color: "#c0caf5"; font.pixelSize: 15; font.bold: true }
                            Text { text: "Enter password for \"" + root.wifiSelectedSsid + "\""; color: "#7dcfff"; font.pixelSize: 12; elide: Text.ElideRight; width: 330 }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: "#292e42" }

                    // Password Input Field
                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: 8
                        color: "#16161e"
                        border.color: pwdInput.activeFocus ? "#7aa2f7" : "#3b4261"
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
                                    color: "#c0caf5"
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
                                    color: "#565f89"
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
                                color: checked ? "#7aa2f7" : "#565f89"
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
                            color: rofiHover.containsMouse ? "#24283b" : "#1f2335"
                            border.color: "#3b4261"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰌾"; color: "#7dcfff"; font.pixelSize: 12 }
                                Text { text: "Rofi Prompt"; color: "#c0caf5"; font.pixelSize: 12 }
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
                            color: cancelHover.containsMouse ? "#24283b" : "#1f2335"
                            border.color: "#3b4261"
                            border.width: 1

                            Text { text: "Cancel"; color: "#c0caf5"; font.pixelSize: 13; anchors.centerIn: parent }

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
                            color: connHover.containsMouse ? "#89b4fa" : "#7aa2f7"

                            Text { text: "Connect"; color: "#1a1b26"; font.pixelSize: 13; font.bold: true; anchors.centerIn: parent }

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
