#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  navigation.zsh — Directory Navigation & Zoxide Integration  ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Zsh Navigation Options ───────────────────────────────────
setopt AUTO_CD              # type dir name to cd
setopt AUTO_PUSHD           # cd pushes to dirstack
setopt PUSHD_IGNORE_DUPS    # no duplicate dirs in stack
setopt PUSHD_MINUS          # swap +/- meaning
setopt PUSHD_SILENT         # don't print dirstack
setopt CDABLE_VARS          # cd to named directories
setopt CHASE_LINKS          # resolve symlinks

# ── Directory Stack (d = show stack, 1-9 = jump) ─────────────
DIRSTACKSIZE=20
alias d='dirs -v | head -20'
for i in {1..9}; do
    alias "$i"="cd +$i"
done

# ── Quick Navigation ─────────────────────────────────────────
alias -- -='cd -'
alias ~='cd ~'

# ── Zoxide Integration ───────────────────────────────────────
if (( $+commands[zoxide] )) && [[ "$ZSH_ENABLE_ZOXIDE" == "true" ]]; then
    eval "$(zoxide init zsh --cmd z)"
fi

# ── Bookmarks ─────────────────────────────────────────────────
typeset -gA ZSH_BOOKMARKS
ZSH_BOOKMARKS=(
    home      "$HOME"
    config    "$HOME/.config"
    projects  "$HOME/projects"
    downloads "$HOME/Downloads"
    documents "$HOME/Documents"
    dots      "$HOME/DARK_NIRI"
)

# Jump to bookmark
bm() {
    if [[ -z "$1" ]]; then
        _zsh_info "Bookmarks:"
        for key val in "${(@kv)ZSH_BOOKMARKS}"; do
            printf "  %s%-12s%s → %s\n" "$C_CYAN" "$key" "$C_RESET" "$val"
        done
        return
    fi
    if [[ -n "${ZSH_BOOKMARKS[$1]}" ]]; then
        cd "${ZSH_BOOKMARKS[$1]}"
    else
        _zsh_error "Bookmark '$1' not found"
    fi
}

# Add bookmark
bm-add() {
    local name="${1:?Usage: bm-add <name> [path]}"
    local path="${2:-$PWD}"
    ZSH_BOOKMARKS[$name]="$path"
    _zsh_success "Bookmark '$name' → $path"
}

# ── Fuzzy cd (fzf + zoxide) ──────────────────────────────────
if (( $+commands[fzf] )) && [[ "$ZSH_ENABLE_FZF" == "true" ]]; then
    # fzf-powered directory browser
    fcd() {
        local dir
        dir=$(command find "${1:-.}" -type d 2>/dev/null | \
              fzf --height=40% --layout=reverse --border \
                  --preview 'eza -1 --color=always {} 2>/dev/null || ls -1 --color=always {}' \
                  --prompt="Dir ❯ ") && cd "$dir"
    }
fi

# ── Recent Directories ──────────────────────────────────────
# chpwd hook to track recent dirs
typeset -g _ZSH_RECENT_DIRS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/recent-dirs"
[[ -d "${_ZSH_RECENT_DIRS_FILE:h}" ]] || mkdir -p "${_ZSH_RECENT_DIRS_FILE:h}"

_zsh_track_recent_dir() {
    # Don't track $HOME or /tmp
    [[ "$PWD" == "$HOME" || "$PWD" == /tmp* ]] && return
    # Prepend to recent dirs, deduplicate, keep 50
    {
        echo "$PWD"
        [[ -f "$_ZSH_RECENT_DIRS_FILE" ]] && command cat "$_ZSH_RECENT_DIRS_FILE"
    } | awk '!seen[$0]++' | head -50 > "${_ZSH_RECENT_DIRS_FILE}.tmp" 2>/dev/null
    command mv -f "${_ZSH_RECENT_DIRS_FILE}.tmp" "$_ZSH_RECENT_DIRS_FILE" 2>/dev/null
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _zsh_track_recent_dir

# Interactive recent directory selector
recent() {
    if [[ ! -f "$_ZSH_RECENT_DIRS_FILE" ]]; then
        _zsh_info "No recent directories yet"
        return
    fi
    if (( $+commands[fzf] )); then
        local dir
        dir=$(cat "$_ZSH_RECENT_DIRS_FILE" | fzf --height=40% --layout=reverse --border \
              --preview 'eza -1 --color=always {} 2>/dev/null || ls -1 --color=always {}' \
              --prompt="Recent ❯ ")
        [[ -n "$dir" && -d "$dir" ]] && cd "$dir"
    else
        cat -n "$_ZSH_RECENT_DIRS_FILE" | head -20
    fi
}
