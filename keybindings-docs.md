# Dark Niri Keybindings Documentation

This document outlines the custom keybindings configured in your Niri dotfiles (`niri/config.kdl`).
Niri uses `Mod` as the primary modifier, which maps to your **Super** (Windows/Command) key.

## Core Applications & Utilities
| Shortcut | Action | Command |
| :--- | :--- | :--- |
| `Super + Enter` | Open Terminal | `alacritty` |
| `Super + Space` | Open App Launcher | `rofi -show drun -theme $HOME/DARK_NIRI/rofi/config.rasi` |
| `Super + V` | Clipboard History | `cliphist list \| rofi -dmenu ... \| cliphist decode \| wl-copy` |
| `Print` | Area Screenshot | `grim -g "$(slurp)" $FILE && wl-copy < $FILE` (saved to `~/SCREEN/screenshots/`) |
| `Super + Print` | Fullscreen Screenshot | `grim $FILE && wl-copy < $FILE` (saved to `~/SCREEN/screenshots/`) |
| `Super + Shift + /` | Show Hotkey Overlay | `show-hotkey-overlay` |

## Window Management
| Shortcut | Action | Notes |
| :--- | :--- | :--- |
| `Alt + F` | Close focused window | `close-window` |
| `Super + Left / Right` | Focus column left / right | `focus-column-left` / `focus-column-right` |
| `Super + Up / Down` | Focus window up / down inside column | `focus-window-up` / `focus-window-down` |
| `Super + Shift + Left / Right` | Move column left / right | `move-column-left` / `move-column-right` |
| `Super + Shift + Up / Down` | Move window up / down inside column | `move-window-up` / `move-window-down` |
| `Super + F` | Maximize current column | Expands column to full screen width |
| `Super + Shift + F` | Fullscreen current window | Hides status bar and takes over entire screen |
| `Super + C` | Center current column | Centers active column in viewport |

> [!NOTE]
> **Automatic Maximization**: `niri/config.kdl` includes a global window rule (`window-rule { default-column-width { proportion 1.0; } }`) so all newly launched applications open full-width (equivalent to pressing `Super + F`) automatically.

## Workspaces
| Shortcut | Action |
| :--- | :--- |
| `Super + 1 .. 5` | Focus workspace 1 to 5 (`focus-workspace 1..5`) |
| `Super + Shift + 1 .. 5` | Move current column to workspace 1 to 5 (`move-column-to-workspace 1..5`) |

## System & Media Keys (OSD Integrated)
All hardware media and backlight keys trigger `$HOME/DARK_NIRI/niri/osd.sh` for synchronous on-screen feedback via Mako:

| Shortcut | Action | Backend Command |
| :--- | :--- | :--- |
| `Super + Shift + E` | Quit Niri Session | `quit` |
| `Super + Shift + P` | Power Off Monitors | `power-off-monitors` |
| `Fn + Volume Up` | Raise Volume (+5%) | `$HOME/DARK_NIRI/niri/osd.sh vol-up` (`wpctl`) |
| `Fn + Volume Down` | Lower Volume (-5%) | `$HOME/DARK_NIRI/niri/osd.sh vol-down` (`wpctl`) |
| `Fn + Mute` | Toggle Audio Mute | `$HOME/DARK_NIRI/niri/osd.sh vol-mute` (`wpctl`) |
| `Fn + Mic Mute` | Toggle Mic Mute | `$HOME/DARK_NIRI/niri/osd.sh mic-mute` (`wpctl`) |
| `Fn + Brightness Up` | Increase Brightness (+5%) | `$HOME/DARK_NIRI/niri/osd.sh bri-up` (`brightnessctl`) |
| `Fn + Brightness Down`| Decrease Brightness (-5%)| `$HOME/DARK_NIRI/niri/osd.sh bri-down` (`brightnessctl`) |

> [!TIP]
> Press `Super + Shift + /` at any time to bring up the built-in Niri Hotkey Overlay directly on screen.
