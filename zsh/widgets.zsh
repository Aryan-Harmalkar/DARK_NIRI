#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  widgets.zsh — ZLE Widgets & Interactive Helpers             ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Sudo Toggle Widget (Esc-Esc) ─────────────────────────────
_zsh_widget_sudo() {
    if [[ "$BUFFER" == sudo\ * ]]; then
        BUFFER="${BUFFER#sudo }"
        CURSOR=$(( CURSOR - 5 ))
    else
        BUFFER="sudo $BUFFER"
        CURSOR=$(( CURSOR + 5 ))
    fi
}
zle -N _zsh_widget_sudo
bindkey '\e\e' _zsh_widget_sudo

# ── Copy Current Line to Clipboard ───────────────────────────
_zsh_widget_copy_line() {
    echo -n "$BUFFER" | _zsh_clipboard_copy
    zle -M "Copied to clipboard"
}
zle -N _zsh_widget_copy_line
bindkey '^X^C' _zsh_widget_copy_line

# ── Insert Last Command Output ───────────────────────────────
_zsh_widget_last_result() {
    LBUFFER+="$(fc -e - 2>/dev/null)"
}
zle -N _zsh_widget_last_result

# ── Smart Dot Expansion (... → ../..) ────────────────────────
_zsh_widget_expand_dots() {
    if [[ "$LBUFFER" == *.. ]]; then
        LBUFFER+="/.."
    else
        LBUFFER+="."
    fi
}
zle -N _zsh_widget_expand_dots
bindkey '.' _zsh_widget_expand_dots

# ── Inline Calculator (= to evaluate) ────────────────────────
_zsh_widget_calc() {
    if [[ "$BUFFER" == =* ]]; then
        local expr="${BUFFER#=}"
        local result=$(python3 -c "from math import *; print($expr)" 2>/dev/null)
        if [[ -n "$result" ]]; then
            BUFFER="$result"
            CURSOR=$#BUFFER
            zle -M "= $expr → $result"
        fi
    fi
}
zle -N _zsh_widget_calc
bindkey '^X=' _zsh_widget_calc

# ── Run-Help (Alt+H for man page) ────────────────────────────
autoload -Uz run-help
(( $+aliases[run-help] )) && unalias run-help
bindkey '\eh' run-help

# ── URL Quote Paste ──────────────────────────────────────────
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
