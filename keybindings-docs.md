# Dark Niri Keybindings Documentation

This document outlines the custom keybindings configured in your Niri dotfiles.
Niri uses `Mod` as the primary modifier, which maps to your **Super** (Windows/Command) key.

## Core Applications
| Shortcut | Action | Command |
| :--- | :--- | :--- |
| `Super + Enter` | Open Terminal | `alacritty` |
| `Super + Space` | Open App Launcher | `fuzzel` |

## Window Management
| Shortcut | Action |
| :--- | :--- |
| `Alt + F` | Close the focused window |
| `Super + Left/Right` | Focus column left or right |
| `Super + Up/Down` | Focus window up or down inside a column |
| `Super + Shift + Left/Right` | Move column left or right |
| `Super + Shift + Up/Down` | Move window up or down inside a column |
| `Super + F` | Maximize current column |
| `Super + Shift + F` | Fullscreen current window |
| `Super + C` | Center current column |

## Workspaces
| Shortcut | Action |
| :--- | :--- |
| `Super + 1..5` | Focus workspace 1 to 5 |
| `Super + Shift + 1..5` | Move current column to workspace 1 to 5 |

## System & Fn Keys
| Shortcut | Action | Backend Command |
| :--- | :--- | :--- |
| `Super + Shift + E` | Quit Niri | `quit` |
| `Super + Shift + P` | Power off monitors | `power-off-monitors` |
| `Fn + Volume Up` | Raise Volume | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+` |
| `Fn + Volume Down` | Lower Volume | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-` |
| `Fn + Mute` | Toggle Audio Mute | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` |
| `Fn + Mic Mute` | Toggle Mic Mute | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` |
| `Fn + Brightness Up` | Increase Brightness | `brightnessctl set 10%+` |
| `Fn + Brightness Down`| Decrease Brightness | `brightnessctl set 10%-` |

> [!TIP]
> You can view all currently bound shortcuts by pressing `Super + Shift + /` to bring up the Niri Hotkey Overlay.
