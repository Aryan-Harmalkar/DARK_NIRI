#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  lib/colors.zsh — Tokyo Night Color Palette                  ║
# ║  ANSI color definitions for prompts and output               ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Raw ANSI Colors (for echo/print) ─────────────────────────
typeset -g C_RESET=$'\033[0m'
typeset -g C_BOLD=$'\033[1m'
typeset -g C_DIM=$'\033[2m'
typeset -g C_ITALIC=$'\033[3m'
typeset -g C_UNDERLINE=$'\033[4m'

# Tokyo Night palette (256-color approximation)
typeset -g C_RED=$'\033[38;2;247;118;142m'       # #f7768e
typeset -g C_GREEN=$'\033[38;2;158;206;106m'     # #9ece6a
typeset -g C_YELLOW=$'\033[38;2;224;175;104m'    # #e0af68
typeset -g C_BLUE=$'\033[38;2;122;162;247m'      # #7aa2f7
typeset -g C_MAGENTA=$'\033[38;2;187;154;247m'   # #bb9af7
typeset -g C_CYAN=$'\033[38;2;125;207;255m'      # #7dcfff
typeset -g C_WHITE=$'\033[38;2;192;202;245m'     # #c0caf5
typeset -g C_ORANGE=$'\033[38;2;255;158;100m'    # #ff9e64
typeset -g C_TEAL=$'\033[38;2;115;218;202m'      # #73daca
typeset -g C_GRAY=$'\033[38;2;86;95;137m'        # #565f89
typeset -g C_BG=$'\033[38;2;26;27;38m'           # #1a1b26

# ── Prompt-safe Colors (with %{ %} escapes) ──────────────────
typeset -g P_RESET='%f%b'
typeset -g P_BOLD='%B'
typeset -g P_RED='%F{#f7768e}'
typeset -g P_GREEN='%F{#9ece6a}'
typeset -g P_YELLOW='%F{#e0af68}'
typeset -g P_BLUE='%F{#7aa2f7}'
typeset -g P_MAGENTA='%F{#bb9af7}'
typeset -g P_CYAN='%F{#7dcfff}'
typeset -g P_WHITE='%F{#c0caf5}'
typeset -g P_ORANGE='%F{#ff9e64}'
typeset -g P_TEAL='%F{#73daca}'
typeset -g P_GRAY='%F{#565f89}'

# ── Fallback for basic terminals ─────────────────────────────
if [[ "$TERM" == "linux" || "$TERM" == "dumb" ]]; then
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_MAGENTA=$'\033[35m'
    C_CYAN=$'\033[36m'
    C_WHITE=$'\033[37m'
    C_ORANGE=$'\033[33m'
    C_TEAL=$'\033[36m'
    C_GRAY=$'\033[90m'

    P_RED='%F{red}'
    P_GREEN='%F{green}'
    P_YELLOW='%F{yellow}'
    P_BLUE='%F{blue}'
    P_MAGENTA='%F{magenta}'
    P_CYAN='%F{cyan}'
    P_WHITE='%F{white}'
    P_ORANGE='%F{yellow}'
    P_TEAL='%F{cyan}'
    P_GRAY='%F{8}'
fi
