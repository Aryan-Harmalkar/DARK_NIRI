#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  lib/helpers.zsh — Core Helper Functions                     ║
# ║  Logging, spinners, environment detection utilities          ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Unicode Detection ─────────────────────────────────────────
_zsh_has_unicode() {
    [[ "$LANG" == *UTF-8* || "$LANG" == *utf8* || \
       "$LC_ALL" == *UTF-8* || "$LC_CTYPE" == *UTF-8* ]]
}

# ── Icon Helpers ──────────────────────────────────────────────
_zsh_icon() {
    if _zsh_has_unicode; then
        echo -n "$1"
    else
        echo -n "$2"
    fi
}

# ── Logging Functions ─────────────────────────────────────────
_zsh_info() {
    local icon=$(_zsh_icon "ℹ" "i")
    printf "%s %s%s%s %s%s\n" "$C_BLUE" "$C_BOLD" "$icon" "$C_RESET" "$1" "$C_RESET"
}

_zsh_success() {
    local icon=$(_zsh_icon "✓" "+")
    printf "%s%s%s%s %s%s\n" "$C_GREEN" "$C_BOLD" "$icon" "$C_RESET" "$1" "$C_RESET"
}

_zsh_warning() {
    local icon=$(_zsh_icon "⚠" "!")
    printf "%s%s%s%s %s%s\n" "$C_YELLOW" "$C_BOLD" "$icon" "$C_RESET" "$1" "$C_RESET"
}

_zsh_error() {
    local icon=$(_zsh_icon "✗" "x")
    printf "%s%s%s%s %s%s\n" "$C_RED" "$C_BOLD" "$icon" "$C_RESET" "$1" "$C_RESET"
}

# ── Spinner ───────────────────────────────────────────────────
typeset -g _ZSH_SPINNER_PID=0
typeset -g _ZSH_SPINNER_FRAMES
if _zsh_has_unicode; then
    _ZSH_SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
else
    _ZSH_SPINNER_FRAMES=("|" "/" "-" "\\")
fi

_zsh_spinner_start() {
    local msg="${1:-Working...}"
    (
        local i=0
        while true; do
            printf "\r  %s%s%s %s" "$C_CYAN" "${_ZSH_SPINNER_FRAMES[$((i % ${#_ZSH_SPINNER_FRAMES[@]} + 1))]}" "$C_RESET" "$msg"
            sleep 0.08
            ((i++))
        done
    ) &
    _ZSH_SPINNER_PID=$!
    disown $_ZSH_SPINNER_PID 2>/dev/null
}

_zsh_spinner_stop() {
    local success="${1:-true}"
    if (( _ZSH_SPINNER_PID > 0 )); then
        kill $_ZSH_SPINNER_PID 2>/dev/null
        wait $_ZSH_SPINNER_PID 2>/dev/null
        _ZSH_SPINNER_PID=0
    fi
    printf "\r\033[2K"
    if [[ "$success" == "true" ]]; then
        _zsh_success "${2:-Done}"
    else
        _zsh_error "${2:-Failed}"
    fi
}

# ── Environment Checks ───────────────────────────────────────
_zsh_is_ssh() {
    [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]
}

_zsh_is_root() {
    (( EUID == 0 ))
}

_zsh_is_interactive() {
    [[ -o interactive ]]
}

_zsh_is_login() {
    [[ -o login ]]
}

# ── Feature Flag Check ───────────────────────────────────────
_zsh_feature_enabled() {
    local var="ZSH_ENABLE_${1:u}"
    [[ "${(P)var}" == "true" ]]
}

# ── Safe Source ───────────────────────────────────────────────
_zsh_source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

# ── Timer Helpers ─────────────────────────────────────────────
_zsh_format_duration() {
    local total=$1
    if (( total >= 3600 )); then
        printf "%dh %dm %ds" $((total / 3600)) $(((total % 3600) / 60)) $((total % 60))
    elif (( total >= 60 )); then
        printf "%dm %ds" $((total / 60)) $((total % 60))
    else
        printf "%.1fs" "$total"
    fi
}

# ── Horizontal Rule ──────────────────────────────────────────
_zsh_hr() {
    local cols=${COLUMNS:-80}
    printf '%s%*s%s\n' "$C_GRAY" "$cols" '' "$C_RESET" | tr ' ' '─'
}
