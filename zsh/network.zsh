#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  network.zsh — Network Information & Helpers                ║
# ╚══════════════════════════════════════════════════════════════╝

# ── myip: Public IP address ──────────────────────────────────
myip() {
    local ip
    ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || \
         curl -s --max-time 5 https://api.ipify.org 2>/dev/null || \
         curl -s --max-time 5 https://icanhazip.com 2>/dev/null)
    if [[ -n "$ip" ]]; then
        printf "  %sPublic IP:%s %s\n" "$C_CYAN" "$C_RESET" "$ip"
    else
        _zsh_warning "Could not determine public IP"
    fi
}

# ── localip: Local IP addresses ──────────────────────────────
localip() {
    if (( $+commands[ip] )); then
        ip -4 addr show | awk '/inet / && !/127.0.0.1/ {printf "  %-12s %s\n", $NF, $2}'
    elif (( $+commands[hostname] )); then
        hostname -I 2>/dev/null
    fi
}

# ── ports: Show listening ports ──────────────────────────────
ports() {
    if (( $+commands[ss] )); then
        ss -tulnp 2>/dev/null | head -30
    elif (( $+commands[netstat] )); then
        netstat -tulnp 2>/dev/null | head -30
    else
        _zsh_warning "Neither ss nor netstat found"
    fi
}

# ── wifi: WiFi status / list ─────────────────────────────────
wifi() {
    if ! (( $+commands[nmcli] )); then
        _zsh_warning "nmcli not found (install NetworkManager)"
        return 1
    fi
    case "${1:-status}" in
        status|s) nmcli general status && echo && nmcli device wifi show 2>/dev/null ;;
        list|l)   nmcli device wifi list --rescan yes ;;
        on)       nmcli radio wifi on && _zsh_success "WiFi enabled" ;;
        off)      nmcli radio wifi off && _zsh_success "WiFi disabled" ;;
        connect|c)
            if [[ -z "$2" ]]; then
                _zsh_error "Usage: wifi connect <SSID> [password]"
                return 1
            fi
            if [[ -n "$3" ]]; then
                nmcli device wifi connect "$2" password "$3"
            else
                nmcli device wifi connect "$2"
            fi
            ;;
        *)
            echo "Usage: wifi [status|list|on|off|connect <SSID> [pass]]"
            ;;
    esac
}

# ── netinfo: Full network information ────────────────────────
netinfo() {
    echo
    printf "  %s%s Network Information%s\n" "$C_BOLD" "$C_CYAN" "$C_RESET"
    _zsh_hr

    local sep=$(_zsh_icon "│" "|")

    # Hostname
    printf "  %s Hostname  %s%s%s\n" "$sep" "$C_BLUE" "$(hostname)" "$C_RESET"

    # Local IPs
    if (( $+commands[ip] )); then
        ip -4 addr show 2>/dev/null | awk '/inet / && !/127.0.0.1/ {
            printf "  '"$sep"' %-10s %s'"$C_GREEN"'%s'"$C_RESET"'\n", $NF, "", $2
        }'
    fi

    # Default gateway
    if (( $+commands[ip] )); then
        local gw=$(ip route show default 2>/dev/null | awk '{print $3; exit}')
        [[ -n "$gw" ]] && printf "  %s Gateway   %s%s%s\n" "$sep" "$C_YELLOW" "$gw" "$C_RESET"
    fi

    # DNS
    if [[ -f /etc/resolv.conf ]]; then
        local dns=$(grep '^nameserver' /etc/resolv.conf | head -1 | awk '{print $2}')
        [[ -n "$dns" ]] && printf "  %s DNS       %s%s%s\n" "$sep" "$C_YELLOW" "$dns" "$C_RESET"
    fi

    # WiFi SSID
    if (( $+commands[nmcli] )); then
        local ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
        [[ -n "$ssid" ]] && printf "  %s WiFi      %s%s%s\n" "$sep" "$C_MAGENTA" "$ssid" "$C_RESET"
    fi

    _zsh_hr
    echo
}

# ── speedtest: Quick download speed test ─────────────────────
speedtest() {
    if (( $+commands[speedtest-cli] )); then
        speedtest-cli --simple
    elif (( $+commands[curl] )); then
        _zsh_info "Quick speed test (downloading 10MB)..."
        curl -s -o /dev/null -w "Download: %{speed_download} bytes/sec (%{time_total}s)\n" \
            https://speed.hetzner.de/10MB.bin 2>/dev/null
    fi
}

# ── ping-test: Quick connectivity check ──────────────────────
ping-test() {
    local targets=("1.1.1.1" "8.8.8.8" "google.com")
    for target in "${targets[@]}"; do
        if ping -c 1 -W 2 "$target" &>/dev/null; then
            _zsh_success "$target reachable"
        else
            _zsh_error "$target unreachable"
        fi
    done
}
