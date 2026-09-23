#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  system.zsh — System Information & Diagnostics              ║
# ╚══════════════════════════════════════════════════════════════╝

[[ "$ZSH_ENABLE_SYSTEM_INFO" == "true" ]] || return 0

# ── sysinfo: Comprehensive System Overview ───────────────────
sysinfo() {
    local check=$(_zsh_icon "✓" "+")
    local sep=$(_zsh_icon "│" "|")
    echo
    printf "  %s%s System Information%s\n" "$C_BOLD" "$C_CYAN" "$C_RESET"
    _zsh_hr

    # OS
    local os=$(_zsh_detect_os)
    printf "  %s OS         %s %s\n" "$sep" "$C_BLUE" "$os$C_RESET"

    # Kernel
    printf "  %s Kernel     %s %s\n" "$sep" "$C_BLUE" "$(uname -r)$C_RESET"

    # Uptime
    if (( $+commands[uptime] )); then
        local up=$(uptime -p 2>/dev/null | sed 's/up //')
        printf "  %s Uptime     %s %s\n" "$sep" "$C_GREEN" "${up:-unknown}$C_RESET"
    fi

    # Shell
    printf "  %s Shell      %s zsh %s\n" "$sep" "$C_TEAL" "${ZSH_VERSION}$C_RESET"

    # Terminal
    local term=$(_zsh_detect_terminal)
    printf "  %s Terminal   %s %s\n" "$sep" "$C_TEAL" "$term$C_RESET"

    # DE/WM
    local de=$(_zsh_detect_de)
    printf "  %s DE/WM      %s %s\n" "$sep" "$C_MAGENTA" "$de$C_RESET"

    # Display
    local display=$(_zsh_detect_display_server)
    printf "  %s Display    %s %s\n" "$sep" "$C_MAGENTA" "$display$C_RESET"

    # CPU
    if [[ -f /proc/cpuinfo ]]; then
        local cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')
        printf "  %s CPU        %s %s\n" "$sep" "$C_YELLOW" "$cpu$C_RESET"
    fi

    # GPU
    if (( $+commands[lspci] )); then
        local gpu=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1 | sed 's/.*: //')
        [[ -n "$gpu" ]] && printf "  %s GPU        %s %s\n" "$sep" "$C_YELLOW" "$gpu$C_RESET"
    fi

    # Memory
    if [[ -f /proc/meminfo ]]; then
        local mem_total=$(awk '/MemTotal/ {printf "%.1f", $2/1048576}' /proc/meminfo)
        local mem_avail=$(awk '/MemAvailable/ {printf "%.1f", $2/1048576}' /proc/meminfo)
        local mem_used=$(printf "%.1f" "$(echo "$mem_total - $mem_avail" | bc 2>/dev/null || echo 0)")
        printf "  %s Memory     %s %s / %s GiB\n" "$sep" "$C_ORANGE" "${mem_used}$C_RESET" "${mem_total}"
    fi

    # Disk
    local disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}')
    [[ -n "$disk_info" ]] && printf "  %s Disk (/)   %s %s\n" "$sep" "$C_ORANGE" "$disk_info$C_RESET"

    # Packages
    if (( $+commands[pacman] )); then
        local pkg_count=$(pacman -Q 2>/dev/null | wc -l)
        printf "  %s Packages   %s %s (pacman)\n" "$sep" "$C_GREEN" "$pkg_count$C_RESET"
    fi

    _zsh_hr
    echo
}

# ── zsh-doctor: Environment Diagnostic ───────────────────────
zsh-doctor() {
    echo
    printf "  %s%s Zsh Environment Diagnostic%s\n" "$C_BOLD" "$C_CYAN" "$C_RESET"
    _zsh_hr

    local check=$(_zsh_icon "✓" "+")
    local warn=$(_zsh_icon "⚠" "!")
    local cross=$(_zsh_icon "✗" "x")

    # Core
    _zsh_success "zsh ${ZSH_VERSION}"
    (( $+commands[git] )) && _zsh_success "git $(git --version 2>/dev/null | awk '{print $3}')" || _zsh_error "git not found"

    echo
    printf "  %s%sOptional Tools:%s\n" "$C_BOLD" "$C_BLUE" "$C_RESET"

    local tools=(fzf eza bat fd rg zoxide delta dust duf btop jq yq starship)
    for tool in "${tools[@]}"; do
        if (( $+commands[$tool] )); then
            _zsh_success "$tool"
        else
            _zsh_warning "$tool (not installed)"
        fi
    done

    echo
    printf "  %s%sPlugins:%s\n" "$C_BOLD" "$C_BLUE" "$C_RESET"
    [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
        _zsh_success "zsh-autosuggestions" || _zsh_warning "zsh-autosuggestions (not found)"
    [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
        _zsh_success "zsh-syntax-highlighting" || _zsh_warning "zsh-syntax-highlighting (not found)"

    echo
    printf "  %s%sConfiguration:%s\n" "$C_BOLD" "$C_BLUE" "$C_RESET"
    [[ -f "${ZDOTDIR:-$HOME}/.zshrc" ]] && _zsh_success ".zshrc exists" || _zsh_error ".zshrc missing"
    [[ "$SHELL" == */zsh ]] && _zsh_success "Login shell: $SHELL" || _zsh_warning "Login shell: $SHELL (not zsh)"

    # Syntax check
    if zsh -n "${ZDOTDIR:-$HOME/.config/zsh}/.zshrc" 2>/dev/null; then
        _zsh_success ".zshrc syntax OK"
    else
        _zsh_error ".zshrc has syntax errors"
    fi

    # Startup time
    local start_time=$EPOCHREALTIME
    zsh -i -c exit 2>/dev/null
    local elapsed=$(printf "%.0f" "$(( (EPOCHREALTIME - start_time) * 1000 ))")
    if (( elapsed < 100 )); then
        _zsh_success "Startup time: ~${elapsed}ms"
    elif (( elapsed < 300 )); then
        _zsh_warning "Startup time: ~${elapsed}ms (slightly slow)"
    else
        _zsh_error "Startup time: ~${elapsed}ms (slow)"
    fi

    _zsh_hr
    echo
}

# ── zsh-install-deps: Show recommended packages ─────────────
zsh-install-deps() {
    echo
    printf "  %s%s Recommended Packages (Arch Linux)%s\n" "$C_BOLD" "$C_CYAN" "$C_RESET"
    _zsh_hr

    local -A packages=(
        [fzf]="fzf"
        [eza]="eza"
        [bat]="bat"
        [fd]="fd"
        [rg]="ripgrep"
        [zoxide]="zoxide"
        [delta]="git-delta"
        [dust]="dust"
        [duf]="duf"
        [btop]="btop"
        [jq]="jq"
        [yq]="yq"
        [starship]="starship"
    )

    local missing=()
    for cmd pkg in "${(@kv)packages}"; do
        if (( $+commands[$cmd] )); then
            _zsh_success "$pkg ($cmd)"
        else
            _zsh_warning "$pkg ($cmd) — not installed"
            missing+=("$pkg")
        fi
    done

    # Zsh plugins
    [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] || missing+=(zsh-autosuggestions)
    [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] || missing+=(zsh-syntax-highlighting)

    if (( ${#missing[@]} > 0 )); then
        echo
        printf "  %sInstall missing packages:%s\n" "$C_YELLOW" "$C_RESET"
        local aur=$(_zsh_aur_helper)
        local mgr="${aur:-sudo pacman}"
        printf "  %s -S --needed %s\n" "$mgr" "${missing[*]}"
    else
        echo
        _zsh_success "All recommended packages installed!"
    fi
    _zsh_hr
    echo
}

# ── zsh-config: Edit configuration ───────────────────────────
zsh-config() {
    ${EDITOR:-nano} "${ZSH_CONFIG_DIR}/config.zsh"
}

# ── zsh-update: Reload configuration ─────────────────────────
zsh-update() {
    _zsh_info "Reloading Zsh configuration..."
    exec zsh
}

# ── zsh-reset: Reset to defaults ─────────────────────────────
zsh-reset() {
    if confirm "Reset all feature flags to defaults?"; then
        command cp "${ZSH_CONFIG_DIR}/config.zsh" "${ZSH_CONFIG_DIR}/config.zsh.bak"
        _zsh_success "Config backed up to config.zsh.bak"
        _zsh_info "Edit config.zsh to restore defaults manually, then run: zsh-update"
    fi
}

# ── zsh-backup: Backup current configuration ─────────────────
zsh-backup() {
    local stamp=$(date +%Y%m%d-%H%M%S)
    local dest="$HOME/.config/zsh-backup-${stamp}"
    command cp -a "${ZSH_CONFIG_DIR}" "$dest"
    _zsh_success "Configuration backed up to: $dest"
}
