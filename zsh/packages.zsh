#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  packages.zsh — Arch Linux Package Management Helpers       ║
# ╚══════════════════════════════════════════════════════════════╝

(( $+commands[pacman] )) || return 0

# ── Detect AUR Helper ────────────────────────────────────────
_pkg_mgr() {
    local aur=$(_zsh_aur_helper)
    echo "${aur:-sudo pacman}"
}

# ── update: System Update ────────────────────────────────────
update() {
    local mgr=$(_pkg_mgr)
    _zsh_info "Updating system with: $mgr"
    $mgr -Syu
}

# ── installpkg: Install packages ─────────────────────────────
installpkg() {
    if [[ $# -eq 0 ]]; then
        _zsh_error "Usage: installpkg <package> [package...]"
        return 1
    fi
    local mgr=$(_pkg_mgr)
    _zsh_info "Installing: $*"
    $mgr -S "$@"
}

# ── removepkg: Remove packages (with deps) ──────────────────
removepkg() {
    if [[ $# -eq 0 ]]; then
        _zsh_error "Usage: removepkg <package> [package...]"
        return 1
    fi
    _zsh_warning "This will remove: $* (and unused dependencies)"
    if confirm "Continue?"; then
        sudo pacman -Rns "$@"
    fi
}

# ── searchpkg: Search for packages ──────────────────────────
searchpkg() {
    if [[ $# -eq 0 ]]; then
        _zsh_error "Usage: searchpkg <query>"
        return 1
    fi
    local mgr=$(_pkg_mgr)
    $mgr -Ss "$@"
}

# ── orphans: List orphaned packages ──────────────────────────
orphans() {
    local orphans=$(pacman -Qtdq 2>/dev/null)
    if [[ -z "$orphans" ]]; then
        _zsh_success "No orphaned packages found"
        return
    fi
    echo "$orphans"
    echo
    _zsh_warning "Found $(echo "$orphans" | wc -l) orphaned packages"
    if confirm "Remove all orphans?"; then
        sudo pacman -Rns $(pacman -Qtdq)
    fi
}

# ── cleanup: Clean package cache ─────────────────────────────
cleanup() {
    _zsh_info "Package cache cleanup"

    # Keep last 2 versions of installed, remove uninstalled
    if (( $+commands[paccache] )); then
        _zsh_info "Cleaning pacman cache (keeping 2 versions)..."
        sudo paccache -rk2
        sudo paccache -ruk0
    else
        _zsh_warning "paccache not found (install pacman-contrib)"
        _zsh_info "Running: pacman -Sc"
        if confirm "Clean package cache?"; then
            sudo pacman -Sc
        fi
    fi
}

# ── pkginfo: Show package info ───────────────────────────────
pkginfo() {
    if [[ $# -eq 0 ]]; then
        _zsh_error "Usage: pkginfo <package>"
        return 1
    fi
    if pacman -Qi "$1" 2>/dev/null; then
        return
    fi
    pacman -Si "$1" 2>/dev/null || _zsh_error "Package '$1' not found"
}

# ── pkgfiles: List files owned by package ────────────────────
pkgfiles() {
    if [[ $# -eq 0 ]]; then
        _zsh_error "Usage: pkgfiles <package>"
        return 1
    fi
    pacman -Ql "$1" 2>/dev/null || _zsh_error "Package '$1' not found or not installed"
}

# ── whichpkg: Which package owns a file ──────────────────────
whichpkg() {
    if [[ $# -eq 0 ]]; then
        _zsh_error "Usage: whichpkg <file>"
        return 1
    fi
    pacman -Qo "$1" 2>/dev/null || _zsh_error "No package owns '$1'"
}

# ── pkg-count: Package statistics ────────────────────────────
pkg-count() {
    local total=$(pacman -Q 2>/dev/null | wc -l)
    local explicit=$(pacman -Qe 2>/dev/null | wc -l)
    local deps=$((total - explicit))
    local aur=$(pacman -Qm 2>/dev/null | wc -l)

    printf "  Total:    %s%d%s\n" "$C_BOLD" "$total" "$C_RESET"
    printf "  Explicit: %s%d%s\n" "$C_GREEN" "$explicit" "$C_RESET"
    printf "  Deps:     %s%d%s\n" "$C_GRAY" "$deps" "$C_RESET"
    printf "  AUR:      %s%d%s\n" "$C_CYAN" "$aur" "$C_RESET"
}

# ── Pacman Aliases ───────────────────────────────────────────
alias pac='sudo pacman'
alias pacs='pacman -Ss'
alias paci='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacq='pacman -Qi'
alias pacl='pacman -Ql'
alias pacu='sudo pacman -Syu'
