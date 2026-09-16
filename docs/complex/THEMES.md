# 🎨 Theming System & 1-Click Theme Orchestrator

Dark Niri features an atomic **1-Click Whole-System Theme Engine** driven by native Rust (`theme-manager`) and QuickShell reactive state (`Theme.qml`).

A single click in the QuickShell Settings GUI (`btn => themes`) or bar quick button (`󰏘`) instantly synchronizes the entire desktop suite in real-time without restarting your session.

---

## 1. Unified Subsystem Architecture

When a theme is activated, `theme-manager` updates all desktop subsystems simultaneously:

```
┌────────────────────────────────────────────────────────┐
│   QuickShell Settings GUI: Themes Button (󰏘)           │
│   (Click opens interactive Theme Studio Modal)         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│   dark-tools-rs / theme-manager CLI                    │
│   (Atomic configuration generator & IPC broadcast)     │
└─────┬──────────────┬──────────────┬─────────────┬──────┘
      │              │              │             │
      ▼              ▼              ▼             ▼
┌───────────┐ ┌────────────┐ ┌───────────┐ ┌─────────────┐
│QuickShell │ │ Niri WM    │ │ Rofi &    │ │ Mako        │
│Theme.qml  │ │ theme.kdl  │ │ Fuzzel    │ │ config      │
│(Hot-reload│ │(niri msg   │ │(theme.rasi│ │(makoctl     │
│colors)    │ │load-config)│ │fuzzel.ini)│ │reload)      │
└───────────┘ └────────────┘ └───────────┘ └─────────────┘
      │
      ▼
┌───────────────────────────┐
│ HTML5/Web Wallpaper Engine│
│(wallpaperctl set <theme>) │
└───────────────────────────┘
```

1. **QuickShell**: Reactive `Theme.qml` singleton dynamically updates all bars, pills, modals, sliders, and buttons with smooth color transitions.
2. **Niri (Window Manager)**: Generates `niri/theme.kdl` and reloads compositor state with `niri msg action load-config-file`.
3. **Rofi**: Generates `rofi/theme.rasi` with matching background, foreground, border, and selection colors.
4. **Fuzzel**: Updates `[colors]` in `fuzzel/fuzzel.ini` with corresponding RGBA hex codes.
5. **Mako (Notifications)**: Updates `mako/config` and runs `makoctl reload` for instantaneous live styling.
6. **Wallpaper Engine**: Triggers `wallpaperctl set <wallpaper>` to switch to the theme's curated companion animated HTML or visual wallpaper.

---

## 2. Curated Theme Presets

| ID | Name | Description | Accent | Companion Wallpaper |
| :--- | :--- | :--- | :--- | :--- |
| `tokyo-night` | **Tokyo Night** | Signature cyberpunk neon (cyan, deep blue, violet) | `#7aa2f7` | `cyber-city` |
| `catppuccin-mocha` | **Catppuccin Mocha** | Soothing pastel palette (mauve, sapphire, lavender) | `#cba6f7` | `waves` |
| `cyberpunk-2077` | **Cyberpunk 2077** | High-voltage neon (yellow, hot magenta, electric cyan) | `#fee801` | `cyber-city` |
| `nord-frost` | **Nord Frost** | Clean arctic dark slate, frost cyan, glacial blue | `#88c0d0` | `aurora` |
| `dracula` | **Dracula** | Gothic vampire dark with luminous purple, pink, lime | `#bd93f9` | `particles` |
| `rose-pine` | **Rose Pine** | Warm ethereal pine, rose, and gold minimal aesthetic | `#ebbcba` | `waves` |
| `gruvbox-dark` | **Gruvbox Dark** | Warm retro amber, forest green, earthy terracotta | `#fabd2f` | `fallback` |

---

## 3. CLI Management (`theme-manager`)

The native Rust `theme-manager` binary is located at `quickshell/theme-manager`:

```bash
# List all themes with full color tokens in JSON format
quickshell/theme-manager list

# Get current active theme metadata
quickshell/theme-manager current

# Apply a specific theme instantly
quickshell/theme-manager apply catppuccin-mocha
quickshell/theme-manager apply cyberpunk-2077
quickshell/theme-manager apply tokyo-night

# Cycle to the next theme preset
quickshell/theme-manager next

# Manage status bar style (floating, islands, normal, compact)
quickshell/theme-manager bar-style get
quickshell/theme-manager bar-style set floating
quickshell/theme-manager bar-style set islands
quickshell/theme-manager bar-style set normal
quickshell/theme-manager bar-style set compact
```

---

## 4. Typography & Geometry Tokens

- **Font Family**: `Inter` (UI elements, labels, buttons) and `Inter Bold` (headers, prompts).
- **Icon Font**: `Nerd Font Symbols` (Material / FontAwesome glyphs).
- **Corner Radii**:
  - Floating Island Dock: 22px
  - Bar Indicator Badges / Pills: 14px
  - Flyout Modals: 20px
  - Bento Grid Tiles: 14px
  - Buttons / Inputs: 10px

---

## 5. QuickShell Reactive Token Architecture (`Theme.qml`)

QuickShell widgets bind reactively to the `Theme.qml` singleton registered via `quickshell/components/qmldir`:

```qml
// In any component:
import QtQuick
import "." as Components

Rectangle {
    color: Components.Theme.bgDark
    border.color: Components.Theme.borderSubtle
    radius: Components.Theme.pillRadius

    Text {
        color: Components.Theme.fgPrimary
        text: "Dynamic Themed Widget"
    }
}
```

### Core Token Reference:
- **Surfaces**: `bgDark`, `bgDarkAlpha`, `bgAlt`, `bgCard`, `bgHover`
- **Borders & Dividers**: `borderSubtle`, `borderHover`
- **Theme Accents**: `accentBlue`, `accentCyan`, `accentPurple`, `accentGold`
- **Typography Colors**: `fgPrimary`, `fgSecondary`, `fgMuted`
- **Status Alerts**: `errorRed`, `successGreen`, `warningYellow`
- **Layout & Geometry**: `barStyle`, `panelRadius`, `pillRadius`, `modalRadius`
- **Persistence**: Color tokens and bar styles are persisted across reboots in `quickshell/theme.json` and `quickshell/bar_style.json`.
