# ⌨️ Master Keybindings Reference

This document provides a complete reference for all keyboard shortcuts and hardware media keys configured in Dark Niri.

`Mod` refers to the **Super** key (Windows/Command key).

---

## 1. Master Keybinding Table

| Keybinding | Action | Command / Function | Config File | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| `Mod+Shift+/` | Show Hotkey Overlay | `show-hotkey-overlay` | `niri/config.kdl` | `niri` | Working |
| `Mod+Return` | Launch Terminal | `alacritty` | `niri/config.kdl` | `alacritty` | Working |
| `Mod+Space` | Application Launcher | `rofi -show drun -theme $HOME/DARK_NIRI/rofi/config.rasi` | `niri/config.kdl` | `rofi-wayland` | Working |
| `Alt+F` | Close Window | `close-window` | `niri/config.kdl` | `niri` | Working |
| `Mod+Left` | Focus Column Left | `focus-column-left` | `niri/config.kdl` | `niri` | Working |
| `Mod+Right` | Focus Column Right | `focus-column-right` | `niri/config.kdl` | `niri` | Working |
| `Mod+Up` | Focus Window Up | `focus-window-up` | `niri/config.kdl` | `niri` | Working |
| `Mod+Down` | Focus Window Down | `focus-window-down` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+Left` | Move Column Left | `move-column-left` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+Right`| Move Column Right | `move-column-right` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+Up` | Move Window Up | `move-window-up` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+Down` | Move Window Down | `move-window-down` | `niri/config.kdl` | `niri` | Working |
| `Mod+F` | Maximize Column | `maximize-column` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+F` | Fullscreen Window | `fullscreen-window` | `niri/config.kdl` | `niri` | Working |
| `Mod+C` | Center Column | `center-column` | `niri/config.kdl` | `niri` | Working |
| `Mod+1` | Focus Workspace 1 | `focus-workspace 1` | `niri/config.kdl` | `niri` | Working |
| `Mod+2` | Focus Workspace 2 | `focus-workspace 2` | `niri/config.kdl` | `niri` | Working |
| `Mod+3` | Focus Workspace 3 | `focus-workspace 3` | `niri/config.kdl` | `niri` | Working |
| `Mod+4` | Focus Workspace 4 | `focus-workspace 4` | `niri/config.kdl` | `niri` | Working |
| `Mod+5` | Focus Workspace 5 | `focus-workspace 5` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+1` | Move to Workspace 1 | `move-column-to-workspace 1` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+2` | Move to Workspace 2 | `move-column-to-workspace 2` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+3` | Move to Workspace 3 | `move-column-to-workspace 3` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+4` | Move to Workspace 4 | `move-column-to-workspace 4` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+5` | Move to Workspace 5 | `move-column-to-workspace 5` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+E` | Quit Niri Session | `quit` | `niri/config.kdl` | `niri` | Working |
| `Mod+Shift+P` | Power Off Monitors | `power-off-monitors` | `niri/config.kdl` | `niri` | Working |
| `XF86AudioRaiseVolume` | Volume Up (+5%) | `$HOME/DARK_NIRI/niri/osd.sh vol-up` | `niri/config.kdl` | `wpctl`, `mako` | Working |
| `XF86AudioLowerVolume` | Volume Down (-5%) | `$HOME/DARK_NIRI/niri/osd.sh vol-down` | `niri/config.kdl` | `wpctl`, `mako` | Working |
| `XF86AudioMute` | Toggle Audio Mute | `$HOME/DARK_NIRI/niri/osd.sh vol-mute` | `niri/config.kdl` | `wpctl`, `mako` | Working |
| `XF86AudioMicMute` | Toggle Mic Mute | `$HOME/DARK_NIRI/niri/osd.sh mic-mute` | `niri/config.kdl` | `wpctl`, `mako` | Working |
| `XF86MonBrightnessUp` | Brightness Up (+5%) | `$HOME/DARK_NIRI/niri/osd.sh bri-up` | `niri/config.kdl` | `brightnessctl` | Working |
| `XF86MonBrightnessDown`| Brightness Down (-5%)| `$HOME/DARK_NIRI/niri/osd.sh bri-down` | `niri/config.kdl` | `brightnessctl` | Working |
| `Print` | Area Screenshot | `grim -g "$(slurp)" $FILE && wl-copy < $FILE` | `niri/config.kdl` | `grim`, `slurp` | Working |
| `Mod+Print` | Fullscreen Screenshot | `grim $FILE && wl-copy < $FILE` | `niri/config.kdl` | `grim` | Working |
| `Mod+V` | Clipboard History | `cliphist list | rofi -dmenu ... | cliphist decode | wl-copy` | `niri/config.kdl` | `cliphist`, `rofi` | Working |
