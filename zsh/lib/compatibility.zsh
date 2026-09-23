#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  lib/compatibility.zsh — Fallbacks & Compatibility Layer     ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Ensure autoload functions are available ───────────────────
autoload -Uz add-zsh-hook 2>/dev/null
autoload -Uz is-at-least 2>/dev/null

# ── Zsh Version Check ────────────────────────────────────────
_zsh_version_ok() {
    is-at-least "${1:-5.5}"
}

# ── Safe Plugin Loading ──────────────────────────────────────
_zsh_load_plugin() {
    local name="$1"
    local paths=(
        "/usr/share/zsh/plugins/${name}/${name}.zsh"
        "/usr/share/${name}/${name}.zsh"
        "$HOME/.local/share/zsh/plugins/${name}/${name}.zsh"
        "${ZSH_CONFIG_DIR}/plugins/${name}/${name}.zsh"
    )
    for p in "${paths[@]}"; do
        if [[ -f "$p" ]]; then
            source "$p"
            return 0
        fi
    done
    return 1
}

# ── Safe setopt (won't error on unrecognized options) ────────
_zsh_setopt() {
    for opt in "$@"; do
        setopt "$opt" 2>/dev/null
    done
}

# ── Clipboard Detection ─────────────────────────────────────
_zsh_clipboard_copy() {
    if (( $+commands[wl-copy] )) && [[ -n "$WAYLAND_DISPLAY" ]]; then
        wl-copy
    elif (( $+commands[xclip] )) && [[ -n "$DISPLAY" ]]; then
        xclip -selection clipboard
    elif (( $+commands[pbcopy] )); then
        pbcopy
    else
        cat  # fallback: just output
    fi
}

_zsh_clipboard_paste() {
    if (( $+commands[wl-paste] )) && [[ -n "$WAYLAND_DISPLAY" ]]; then
        wl-paste
    elif (( $+commands[xclip] )) && [[ -n "$DISPLAY" ]]; then
        xclip -selection clipboard -o
    elif (( $+commands[pbpaste] )); then
        pbpaste
    fi
}

# ── Open Command (cross-platform) ───────────────────────────
_zsh_open_cmd() {
    if (( $+commands[xdg-open] )); then echo "xdg-open"
    elif (( $+commands[open] )); then echo "open"
    else echo "echo 'No opener found:'"
    fi
}
