#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  functions.zsh — Interactive Utility Functions               ║
# ╚══════════════════════════════════════════════════════════════╝

# ── mkcd: Create directory and cd into it ─────────────────────
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ── extract: Universal archive extractor ──────────────────────
extract() {
    if [[ ! -f "$1" ]]; then
        _zsh_error "File '$1' does not exist"
        return 1
    fi
    case "$1" in
        *.tar.bz2) tar xjf "$1"    ;;
        *.tar.gz)  tar xzf "$1"    ;;
        *.tar.xz)  tar xJf "$1"    ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.bz2)     bunzip2 "$1"    ;;
        *.rar)     unrar x "$1"    ;;
        *.gz)      gunzip "$1"     ;;
        *.tar)     tar xf "$1"     ;;
        *.tbz2)    tar xjf "$1"    ;;
        *.tgz)     tar xzf "$1"    ;;
        *.zip)     unzip "$1"      ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x "$1"       ;;
        *.xz)      unxz "$1"       ;;
        *.zst)     unzstd "$1"     ;;
        *)         _zsh_error "Don't know how to extract '$1'" ; return 1 ;;
    esac
    _zsh_success "Extracted: $1"
}

# ── backup: Create a timestamped backup ──────────────────────
backup() {
    if [[ ! -e "$1" ]]; then
        _zsh_error "'$1' does not exist"
        return 1
    fi
    local stamp=$(date +%Y%m%d-%H%M%S)
    local dest="${1}.backup-${stamp}"
    command cp -a "$1" "$dest"
    _zsh_success "Backed up to: $dest"
}

# ── weather: Show weather forecast ───────────────────────────
weather() {
    local location="${1:-}"
    curl -s "wttr.in/${location}?format=3" 2>/dev/null || _zsh_warning "Could not fetch weather"
}

weather-full() {
    local location="${1:-}"
    curl -s "wttr.in/${location}" 2>/dev/null || _zsh_warning "Could not fetch weather"
}

# ── cheat: Quick command cheat sheets ─────────────────────────
cheat() {
    if [[ -z "$1" ]]; then
        _zsh_info "Usage: cheat <command>"
        return 1
    fi
    curl -s "cheat.sh/$1" 2>/dev/null || _zsh_warning "Could not fetch cheat sheet for '$1'"
}

# ── open: Smart file opener ──────────────────────────────────
open() {
    local opener=$(_zsh_open_cmd)
    if [[ -z "$1" ]]; then
        $opener . 2>/dev/null &!
    else
        $opener "$@" 2>/dev/null &!
    fi
}

# ── serve: Quick HTTP server ─────────────────────────────────
serve() {
    local port="${1:-8000}"
    _zsh_info "Serving on http://localhost:${port}"
    if (( $+commands[python3] )); then
        python3 -m http.server "$port"
    elif (( $+commands[python] )); then
        python -m http.server "$port"
    else
        _zsh_error "Python not found"
        return 1
    fi
}

# ── up: Go up N directories ──────────────────────────────────
up() {
    local count="${1:-1}"
    local path=""
    for i in $(seq 1 $count); do
        path+="../"
    done
    cd "$path"
}

# ── take: mkcd alias ─────────────────────────────────────────
take() { mkcd "$@" }

# ── tre: tree with sensible defaults ─────────────────────────
tre() {
    if (( $+commands[eza] )); then
        eza --tree --icons --level="${1:-3}" --group-directories-first
    elif (( $+commands[tree] )); then
        tree -C -L "${1:-3}" --dirsfirst
    else
        command find . -maxdepth "${1:-3}" -print | sed -e 's;[^/]*/;│   ;g;s;│   \([^│]\);├── \1;'
    fi
}

# ── sizeof: Directory/file size ──────────────────────────────
sizeof() {
    if (( $+commands[dust] )); then
        dust -d 1 "${1:-.}"
    else
        du -sh "${1:-.}" 2>/dev/null
    fi
}

# ── countdown: Simple countdown timer ────────────────────────
countdown() {
    local secs="${1:-10}"
    while (( secs > 0 )); do
        printf "\r  %s%s%s seconds remaining " "$C_YELLOW" "$secs" "$C_RESET"
        sleep 1
        ((secs--))
    done
    printf "\r\033[2K"
    _zsh_success "Timer complete!"
}

# ── confirm: Ask for confirmation ─────────────────────────────
confirm() {
    local msg="${1:-Are you sure?}"
    printf "%s [y/N] " "$msg"
    read -q reply
    echo
    [[ "$reply" == "y" ]]
}

# ── json: Pretty-print JSON ──────────────────────────────────
json() {
    if (( $+commands[jq] )); then
        if [[ -t 0 ]]; then
            jq '.' "$@"
        else
            jq '.'
        fi
    else
        python3 -m json.tool "$@" 2>/dev/null
    fi
}

# ── calc: Quick calculator ───────────────────────────────────
calc() {
    python3 -c "from math import *; print($*)" 2>/dev/null || echo $(( $@ ))
}

# ── note: Quick note-taking ──────────────────────────────────
note() {
    local notefile="$HOME/.local/share/zsh/notes.md"
    [[ -d "${notefile:h}" ]] || mkdir -p "${notefile:h}"
    if [[ $# -eq 0 ]]; then
        ${EDITOR:-cat} "$notefile"
    else
        echo "- [$(date '+%Y-%m-%d %H:%M')] $*" >> "$notefile"
        _zsh_success "Note saved"
    fi
}

# ── encode/decode: Base64 helpers ─────────────────────────────
encode64() { echo -n "$@" | base64 }
decode64() { echo -n "$@" | base64 -d ; echo }

# ── urlencode/urldecode ──────────────────────────────────────
urlencode() { python3 -c "import urllib.parse; print(urllib.parse.quote('$*'))" }
urldecode() { python3 -c "import urllib.parse; print(urllib.parse.unquote('$*'))" }
