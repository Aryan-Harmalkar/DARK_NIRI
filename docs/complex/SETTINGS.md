# ⚙️ Control Center & Settings Architecture

This document documents `quickshell/components/Settings.qml` (2,936 lines), the primary control hub for Dark Niri.

---

## 1. Component Topology

`Settings.qml` consists of:
1. **Trigger Badge**: Top bar gear icon toggling `isSettingsOpen`.
2. **Main Flyout Surface**: Glassmorphic panel anchored to the top-right corner.
3. **Quick Toggle Grid**:
   - Wi-Fi (Toggle on/off & open Network Modal)
   - Bluetooth (Toggle on/off & open Bluetooth Modal)
   - Audio Output Mute
   - Microphone Mute
   - Screencast Record Trigger
   - Notification Drawer Toggle
   - Wallpaper Gallery Modal Toggle
   - Power Profile Cycler
4. **Interactive Sliders**:
   - Master Volume Slider (`wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ <val>`)
   - Display Brightness Slider (`brightnessctl set <val>%`)
5. **Integrated Modal Dialogs**:
   - **Wi-Fi Manager Modal**: Full network scan, signal quality, security type, WPS connect, password entry popup.
   - **Bluetooth Manager Modal**: Device scan, pairing, trust, connection, audio profile switch (A2DP / HSP).
   - **Wallpaper Gallery Modal**: Static images, animated video wallpapers (`mpvpaper`), canvas solid color selector.
   - **Notification Center**: Interactive notifications feed with per-item dismissal and clear all.
6. **Session Action Bar**:
   - Lock Screen: `swaylock -f || niri msg action power-off-monitors`
   - Reload Desktop Shell: `killall qs; qs -d -p $HOME/DARK_NIRI/quickshell/shell.qml &`
   - Log Out: `niri msg action quit`
   - Reboot: `systemctl reboot`
   - Shutdown: `quickshell/shutdown.sh` (or sudo password prompt)
