# 🔗 Traceability & Dependency Matrix

This document maps every UI component and script in Dark Niri to the exact binary commands it invokes, the providing package, and the exact failure mode if the dependency is missing.

---

## 1. Complete Traceability Table

| UI Component / Script | Invoked Command | Package Provider | Subsystem | Failure Behavior If Missing |
| :--- | :--- | :--- | :--- | :--- |
| `niri/startup.sh` | `dbus-update-activation-environment` | `dbus` | D-Bus / Systemd | Apps may launch with incorrect environment |
| `niri/startup.sh` | `systemctl --user import-environment` | `systemd` | Systemd | User session services fail to connect to Wayland |
| `niri/startup.sh` | `mako -c ...` | `mako` | Notifications | Notifications do not start automatically |
| `niri/startup.sh` | `qs -d -p ...` | `quickshell-git` | Desktop Shell | Top bar does not render on boot |
| `niri/startup.sh` | `wl-paste --watch cliphist store` | `wl-clipboard`, `cliphist` | Clipboard | Clipboard history not tracked |
| `niri/config.kdl` | `alacritty` | `alacritty` | Terminal | `Mod+Return` does nothing |
| `niri/config.kdl` | `rofi -show drun -theme ...` | `rofi-wayland` | Launcher | `Mod+Space` fails to open app launcher |
| `niri/config.kdl` | `grim -g "$(slurp)" $FILE` | `grim`, `slurp` | Screenshots | `Print` area screenshot fails |
| `niri/config.kdl` | `grim $FILE` | `grim` | Screenshots | `Mod+Print` fullscreen screenshot fails |
| `niri/config.kdl` | `cliphist list | rofi ...` | `cliphist`, `rofi-wayland` | Clipboard | `Mod+V` fails to show clipboard history |
| `niri/osd.sh` | `wpctl set-volume / get-volume` | `wireplumber` | Audio | Media volume keys do not adjust sound |
| `niri/osd.sh` | `brightnessctl set / get` | `brightnessctl` | Display | Display brightness keys do nothing |
| `niri/osd.sh` | `notify-send -h string:...` | `libnotify` / `mako` | OSD | Visual volume/brightness popups not displayed |
| `quickshell/wifi.sh` | `nmcli radio wifi` | `networkmanager` | Network | Wi-Fi toggle fails |
| `quickshell/wifi.sh` | `nmcli dev wifi list / connect` | `networkmanager` | Network | Wi-Fi network scanning and connection fail |
| `quickshell/wifi.sh` | `gdbus call ... AccessPoint Flags`| `glib2` / `networkmanager`| Network | WPS flag detection fails (falls back to False) |
| `quickshell/bluetooth.sh`| `bluetoothctl show / devices` | `bluez-utils` | Bluetooth | Bluetooth list is empty |
| `quickshell/bluetooth.sh`| `pactl list cards / set-profile` | `libpulse` | Audio | Bluetooth audio profile (A2DP/HSP) switching fails |
| `quickshell/media.sh` | `playerctl metadata ...` | `playerctl` | Media | Media player widget displays empty / hidden |
| `quickshell/notifications.sh`| `makoctl history -j / list -j`| `mako` | Notifications | Notification center shows 0 notifications |
| `quickshell/notifications.sh`| `makoctl dismiss -n <id> / -a`| `mako` | Notifications | Dismissing notifications has no effect |
| `quickshell/powerprofile.sh`| `powerprofilesctl get / set` | `power-profiles-daemon` | Power | Profile cycling falls back to CPU scaling governor |
| `quickshell/screencast.sh`| `wf-recorder -g ...` | `wf-recorder`, `slurp` | Capture | Screencast recording fails to start |
| `quickshell/screencast.sh`| `killall -SIGUSR1 wf-recorder` | `psmisc`, `wf-recorder` | Capture | Pause/Resume screencast fails |
| `quickshell/shutdown.sh` | `rofi -dmenu -password ...` | `rofi-wayland` | System | Sudo password prompt does not open |
| `quickshell/sysinfo.sh` | `free -b` | `procps-ng` | Monitoring | RAM percentage and used GB calculation fail |
| `quickshell/sysinfo.sh` | `nvidia-smi --query-gpu=...` | `nvidia-utils` | Monitoring | NVIDIA GPU metrics output 0 / inactive |
| `quickshell/wallpaper-engine/engine.py` | `WebKit.WebView()`, `Gtk4LayerShell` | `webkitgtk-6.0`, `gtk4-layer-shell`, `python-gobject` | Wallpaper | HTML/Web wallpaper engine fails to initialize |
| `quickshell/wallpaper-engine/wallpaperctl` | IPC UNIX socket commands | `python` | Wallpaper Controller | CLI wallpaper switching fails |
| `quickshell/components/Workspaces.qml`| `niri msg -j workspaces` | `niri` | Compositor IPC | Workspace indicator pills render empty |
