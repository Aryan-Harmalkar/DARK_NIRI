#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  animations.zsh — Tasteful Terminal Animations               ║
# ║  Fast startup sequence & visual feedback effects            ║
# ╚══════════════════════════════════════════════════════════════╝

[[ "$ZSH_ENABLE_ANIMATIONS" == "true" ]] || return 0

# ── Startup Animation ────────────────────────────────────────
_zsh_startup_animation() {
    [[ "$ZSH_ENABLE_STARTUP_ANIMATION" == "true" ]] || return
    # Don't animate in non-interactive, SSH, or nested shells
    _zsh_is_interactive || return
    (( ${SHLVL:-1} > 1 )) && return
    [[ -n "$ZSH_STARTUP_DONE" ]] && return

    export ZSH_STARTUP_DONE=1

    local style="${ZSH_STARTUP_STYLE:-quick}"

    if [[ "$style" == "none" ]]; then
        return
    fi

    local check=$(_zsh_icon "✓" "+")
    local dot=$(_zsh_icon "●" "*")

    if [[ "$style" == "quick" ]]; then
        # Ultra-fast: single line with animation
        local frames=("$dot" "$dot$dot" "$dot$dot$dot" "$check")
        local msgs=("Loading" "Loading." "Loading.." "Ready")
        for i in 1 2 3 4; do
            printf "\r  %s%s%s %s%s%s" \
                "$C_CYAN" "${frames[$i]}" "$C_RESET" \
                "$C_DIM" "${msgs[$i]}" "$C_RESET"
            if (( i < 4 )); then
                sleep 0.04
            fi
        done
        printf "\r\033[2K"  # clear the line
        return
    fi

    # Full startup animation
    if [[ "$style" == "full" ]]; then
        local steps=(
            "Initializing shell"
            "Loading modules"
            "Checking environment"
        )
        for step in "${steps[@]}"; do
            printf "  %s%s%s %s%s%s" "$C_GRAY" "$dot" "$C_RESET" "$C_DIM" "$step" "$C_RESET"
            sleep 0.04
            printf "\r  %s%s%s %s%s%s\n" "$C_GREEN" "$check" "$C_RESET" "$C_DIM" "$step" "$C_RESET"
        done
        printf "  %s%s%s %sReady%s\n\n" "$C_TEAL" "$check" "$C_RESET" "$C_BOLD" "$C_RESET"
    fi
}

# ── Progress Bar ──────────────────────────────────────────────
_zsh_progress() {
    local current=$1 total=$2 label="${3:-Progress}"
    local width=30
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    local bar_char=$(_zsh_icon "█" "#")
    local empty_char=$(_zsh_icon "░" "-")

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="$bar_char"; done
    for ((i=0; i<empty; i++)); do bar+="$empty_char"; done

    local percent=$(( current * 100 / total ))
    printf "\r  %s%s%s %s%3d%%%s" "$C_TEAL" "$bar" "$C_RESET" "$C_BOLD" "$percent" "$C_RESET"

    (( current == total )) && echo
}

# ── Typing Effect ─────────────────────────────────────────────
_zsh_typewrite() {
    local text="$1" delay="${2:-0.03}"
    for ((i=1; i<=${#text}; i++)); do
        printf "%s" "${text[$i]}"
        sleep "$delay"
    done
    echo
}

# ── Fade-in Text ──────────────────────────────────────────────
_zsh_fadein() {
    local text="$1"
    printf "%s%s%s" "$C_DIM" "$text" "$C_RESET"
    sleep 0.05
    printf "\r%s%s%s" "$C_WHITE" "$text" "$C_RESET"
    echo
}

# ── Git Directory Enter Animation ─────────────────────────────
_zsh_git_enter_animation() {
    [[ "$ZSH_ENABLE_GIT" == "true" ]] || return
    # Only trigger on actual directory changes
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return

    # Don't re-animate if same repo
    [[ "$git_root" == "${_ZSH_LAST_GIT_ROOT:-}" ]] && return
    _ZSH_LAST_GIT_ROOT="$git_root"

    local repo_name="${git_root:t}"
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
    local icon=$(_zsh_icon "" "git")

    printf "  %s%s %s%s%s %s%s%s\n" \
        "$C_TEAL" "$icon" \
        "$C_BOLD" "$repo_name" "$C_RESET" \
        "$C_GRAY" "$branch" "$C_RESET"
}
typeset -g _ZSH_LAST_GIT_ROOT=""
add-zsh-hook chpwd _zsh_git_enter_animation
