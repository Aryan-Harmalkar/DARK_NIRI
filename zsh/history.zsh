#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  history.zsh — Powerful History System                       ║
# ╚══════════════════════════════════════════════════════════════╝

# ── History File & Size ───────────────────────────────────────
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=${ZSH_HISTSIZE:-50000}
SAVEHIST=${ZSH_SAVEHIST:-50000}

# Ensure history directory exists
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

# ── History Options ───────────────────────────────────────────
setopt APPEND_HISTORY          # append to history file
setopt INC_APPEND_HISTORY      # write immediately, not on exit
setopt SHARE_HISTORY           # share between terminals
setopt HIST_IGNORE_DUPS        # ignore consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS    # remove older duplicate entries
setopt HIST_SAVE_NO_DUPS       # don't save duplicates
setopt HIST_FIND_NO_DUPS       # skip duplicates in search
setopt HIST_REDUCE_BLANKS      # trim extra whitespace
setopt HIST_IGNORE_SPACE       # leading space = private command
setopt HIST_VERIFY             # show before executing !! etc.
setopt HIST_EXPIRE_DUPS_FIRST  # expire duplicates first
setopt EXTENDED_HISTORY        # save timestamps

# ── FZF History Search ───────────────────────────────────────
if _zsh_feature_enabled "FZF" && (( $+commands[fzf] )); then
    _fzf_history_search() {
        local selected
        selected=$(fc -rl 1 | \
            awk '!seen[$0]++' | \
            fzf --height=40% --layout=reverse --border \
                --query="${LBUFFER}" \
                --prompt="History ❯ " \
                --preview-window=hidden \
                --no-sort \
                +m)
        if [[ -n "$selected" ]]; then
            local num="${selected%%[[:space:]]*}"
            BUFFER="${selected#*[[:space:]]}"
            # Remove leading whitespace
            BUFFER="${BUFFER#"${BUFFER%%[![:space:]]*}"}"
            CURSOR=$#BUFFER
        fi
        zle reset-prompt
    }
    zle -N _fzf_history_search
fi

# ── History Statistics ────────────────────────────────────────
hist-stats() {
    fc -l 1 | \
        awk '{CMD[$2]++; count++} END {for (a in CMD) print CMD[a], CMD[a]/count*100 "%", a}' | \
        sort -rn | \
        head -${1:-20} | \
        column -t
}
