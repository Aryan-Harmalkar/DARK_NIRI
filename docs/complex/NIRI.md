# 📜 Niri Compositor Configuration & Architecture

This document provides in-depth technical documentation for the Niri scrollable-tiling Wayland compositor as configured in Dark Niri.

---

## 1. Overview & Philosophy

[Niri](https://github.com/YaLTeR/niri) is a scrollable-tiling Wayland compositor. Rather than forcing windows into static grid partitions or manual binary split trees, Niri arranges windows along an infinite horizontal ribbon of columns. Moving the active focus past the screen boundary smoothly scrolls the viewport horizontally.

---

## 2. Configuration Breakdown (`niri/config.kdl`)

### 2.1 Autostart Lifecycle
```kdl
spawn-at-startup "sh" "-c" "$HOME/DARK_NIRI/niri/startup.sh"
```
On compositor boot, Niri executes `startup.sh` via `sh -c` to ensure shell variable expansion ($HOME) and background process management.

### 2.2 Input Device Configuration
```kdl
input {
    keyboard {
        xkb {
            layout "us"
        }
    }
    touchpad {
        tap
        natural-scroll
    }
    mouse {
        // accel-speed 0.2
    }
}
```
- **Keyboard**: Standard US English QWERTY layout.
- **Touchpad**: `tap` is enabled for tap-to-click; `natural-scroll` is enabled (reverse scrolling matching modern touch surfaces).

### 2.3 Layout & Aesthetic Geometry
```kdl
layout {
    gaps 0
    center-focused-column "never"

    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }
    
    default-column-width { proportion 0.5; }
    
    focus-ring {
        off
    }

    border {
        off
    }
    
    struts {
        // top 32 (PanelWindow in QuickShell handles exclusive zone reservation)
    }
}
```
- **Gaps**: `0` for a seamless gapless tiling layout with windows flush against each other.
- **Preset Column Proportions**: 1/3 (0.33333), 1/2 (0.5), and 2/3 (0.66667).
- **Default Column Width**: Windows spawn taking exactly 50% of the screen width.
- **Focus Ring & Border**: Disabled (`off`) for clean, distraction-free window frames without colored focus outlines.

### 2.4 Window Rules
```kdl
window-rule {
    match app-id=r#"^org\.wezfurlong\.wezterm$"#
    default-column-width {}
}
```
Matches WezTerm terminal windows and forces automatic default column width sizing.

---

## 3. Session Startup Orchestration (`niri/startup.sh`)

The autostart script performs strict session hygiene:
1. **Silent Redirection**: `exec >/dev/null 2>&1` prevents stray terminal buffer noise.
2. **Environment Synchronization**: Imports `WAYLAND_DISPLAY` and `XDG_CURRENT_DESKTOP` to D-Bus and systemd user session.
3. **Singleton Enforcement**: Kills existing `mako` and `qs` processes to prevent orphan instances on reload.
4. **Daemon Boot**:
   - `mako -c $HOME/DARK_NIRI/mako/config &`
   - `qs -d -p $HOME/DARK_NIRI/quickshell/shell.qml &`
   - `$HOME/DARK_NIRI/quickshell/wallpaper.sh init &`
   - `wl-paste --watch cliphist store &`
