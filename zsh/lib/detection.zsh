#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  lib/detection.zsh — Tool & Environment Detection            ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Terminal Detection ────────────────────────────────────────
_zsh_detect_terminal() {
    if [[ -n "$KITTY_PID" ]]; then echo "kitty"
    elif [[ "$TERM_PROGRAM" == "WezTerm" ]]; then echo "wezterm"
    elif [[ -n "$ALACRITTY_SOCKET" || -n "$ALACRITTY_LOG" ]]; then echo "alacritty"
    elif [[ "$TERM" == "foot"* ]]; then echo "foot"
    elif [[ "$TERM_PROGRAM" == "vscode" ]]; then echo "vscode"
    elif [[ -n "$GNOME_TERMINAL_SERVICE" ]]; then echo "gnome-terminal"
    elif [[ -n "$KONSOLE_VERSION" ]]; then echo "konsole"
    elif [[ "$TERM" == "xterm"* ]]; then echo "xterm"
    elif [[ "$TERM" == "linux" ]]; then echo "tty"
    else echo "unknown"
    fi
}

# ── Desktop / WM Detection ───────────────────────────────────
_zsh_detect_de() {
    if [[ -n "$NIRI_SOCKET" ]]; then echo "niri"
    elif [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then echo "hyprland"
    elif [[ -n "$SWAYSOCK" ]]; then echo "sway"
    elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then echo "kde"
    elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then echo "gnome"
    elif [[ "$XDG_CURRENT_DESKTOP" == *"XFCE"* ]]; then echo "xfce"
    elif [[ -n "$WAYLAND_DISPLAY" ]]; then echo "wayland"
    elif [[ -n "$DISPLAY" ]]; then echo "x11"
    else echo "tty"
    fi
}

# ── Display Server Detection ─────────────────────────────────
_zsh_detect_display_server() {
    if [[ -n "$WAYLAND_DISPLAY" ]]; then echo "wayland"
    elif [[ -n "$DISPLAY" ]]; then echo "x11"
    else echo "tty"
    fi
}

# ── AUR Helper Detection ─────────────────────────────────────
_zsh_aur_helper() {
    if (( $+commands[paru] )); then echo "paru"
    elif (( $+commands[yay] )); then echo "yay"
    else echo ""
    fi
}

# ── Package Manager Detection ────────────────────────────────
_zsh_pkg_manager() {
    if (( $+commands[pacman] )); then echo "pacman"
    elif (( $+commands[apt] )); then echo "apt"
    elif (( $+commands[dnf] )); then echo "dnf"
    else echo ""
    fi
}

# ── OS Detection ─────────────────────────────────────────────
_zsh_detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release 2>/dev/null
        echo "${PRETTY_NAME:-$NAME}"
    elif (( $+commands[uname] )); then
        uname -s
    else
        echo "unknown"
    fi
}

# ── Terminal Title Support Check ─────────────────────────────
_zsh_supports_title() {
    local term=$(_zsh_detect_terminal)
    [[ "$term" != "tty" && "$term" != "unknown" && "$TERM" != "dumb" && "$TERM" != "linux" ]]
}

# ── Cached Tool Detection (fast lookup) ──────────────────────
typeset -gA _ZSH_TOOL_CACHE
_zsh_has_tool() {
    local tool="$1"
    if [[ -z "${_ZSH_TOOL_CACHE[$tool]+x}" ]]; then
        if (( $+commands[$tool] )); then
            _ZSH_TOOL_CACHE[$tool]=1
        else
            _ZSH_TOOL_CACHE[$tool]=0
        fi
    fi
    (( _ZSH_TOOL_CACHE[$tool] ))
}
