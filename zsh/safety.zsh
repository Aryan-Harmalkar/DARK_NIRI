#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  safety.zsh — Safeguards for Dangerous Commands             ║
# ╚══════════════════════════════════════════════════════════════╝

[[ "$ZSH_ENABLE_SAFETY" == "true" ]] || return 0

# ── Dangerous Command Warning Wrapper ─────────────────────────
_zsh_safety_warn() {
    local cmd="$1"
    shift
    printf "%s%s⚠  WARNING: %s%s\n" "$C_YELLOW" "$C_BOLD" "$cmd $*" "$C_RESET"
    printf "  This operation can cause %sIRREVERSIBLE DATA LOSS%s.\n" "$C_RED$C_BOLD" "$C_RESET"
    printf "  %sPress Enter to continue, Ctrl+C to cancel.%s " "$C_GRAY" "$C_RESET"
    read -r || return 1
}

# ── rm -rf protection ────────────────────────────────────────
safe-rm() {
    local args=("$@")
    local has_rf=false
    local targets=()

    for arg in "${args[@]}"; do
        case "$arg" in
            -rf|-fr|--recursive) has_rf=true ;;
            -*) ;;  # other flags
            *) targets+=("$arg") ;;
        esac
    done

    if $has_rf; then
        for target in "${targets[@]}"; do
            # Protect critical paths
            case "$target" in
                /|/home|/usr|/etc|/var|/boot|/sys|/proc|/dev|"$HOME")
                    _zsh_error "BLOCKED: Refusing to rm -rf $target (critical path)"
                    return 1
                    ;;
            esac
        done
        _zsh_safety_warn "rm" "$@" || return 1
    fi
    command rm "$@"
}
alias rm='safe-rm'

# ── dd protection ────────────────────────────────────────────
safe-dd() {
    _zsh_safety_warn "dd" "$@" || return 1
    command dd "$@"
}
alias dd='safe-dd'

# ── mkfs protection ──────────────────────────────────────────
safe-mkfs() {
    _zsh_safety_warn "mkfs" "$@" || return 1
    command mkfs "$@"
}
# Only alias if mkfs exists
(( $+commands[mkfs] )) && alias mkfs='safe-mkfs'

# ── chmod -R / chown -R warnings ─────────────────────────────
safe-chmod() {
    local has_recursive=false
    for arg in "$@"; do
        [[ "$arg" == "-R" || "$arg" == "--recursive" ]] && has_recursive=true
    done
    if $has_recursive; then
        _zsh_safety_warn "chmod -R" "$@" || return 1
    fi
    command chmod "$@"
}

safe-chown() {
    local has_recursive=false
    for arg in "$@"; do
        [[ "$arg" == "-R" || "$arg" == "--recursive" ]] && has_recursive=true
    done
    if $has_recursive; then
        _zsh_safety_warn "chown -R" "$@" || return 1
    fi
    command chown "$@"
}

# ── Prevent accidental > on existing files ───────────────────
setopt NO_CLOBBER  # Use >| to overwrite intentionally

# ── Correct typos ─────────────────────────────────────────────
setopt CORRECT           # suggest corrections for commands only
# Note: CORRECT_ALL is intentionally NOT set — it's too aggressive
SPROMPT="Correct %F{#f7768e}%R%f to %F{#9ece6a}%r%f? [y/n/a/e] "
