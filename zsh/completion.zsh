#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  completion.zsh — Advanced Tab Completion System             ║
# ╚══════════════════════════════════════════════════════════════╝

[[ "$ZSH_ENABLE_COMPLETION" == "true" ]] || return 0

# ── Initialize Completion ─────────────────────────────────────
# Use cached compinit (regenerate once daily for speed)
autoload -Uz compinit
_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_comp_cache:h}" ]] || mkdir -p "${_comp_cache:h}"

if [[ -f "$_comp_cache" && "$_comp_cache" -nt "${_comp_cache}.zwc" ]] || \
   [[ ! -f "$_comp_cache" ]] || \
   [[ $(date +%j) != $(date -r "$_comp_cache" +%j 2>/dev/null) ]]; then
    compinit -d "$_comp_cache"
    { zcompile "$_comp_cache" } &!
else
    compinit -C -d "$_comp_cache"
fi
unset _comp_cache

# ── General Completion Options ────────────────────────────────
setopt COMPLETE_IN_WORD     # complete from both ends
setopt ALWAYS_TO_END        # move cursor to end after complete
setopt AUTO_MENU            # show menu on second tab
setopt AUTO_LIST            # list choices on ambiguous
setopt AUTO_PARAM_SLASH     # add slash after directory
setopt NO_MENU_COMPLETE     # don't auto-select first match
setopt LIST_PACKED          # compact completion list
setopt LIST_ROWS_FIRST      # sort horizontally

# ── Completion Styling ────────────────────────────────────────
# Group matches by description
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{#7aa2f7}%B── %d ──%b%f'
zstyle ':completion:*:messages' format '%F{#e0af68}%B%d%b%f'
zstyle ':completion:*:warnings' format '%F{#f7768e}No matches for: %d%f'
zstyle ':completion:*:corrections' format '%F{#9ece6a}%d (errors: %e)%f'

# Menu selection with highlighting
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Fuzzy matching (allow 1 error for every 3 chars)
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Directory completion
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

# Process completion
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*:processes' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# SSH/SCP completion
zstyle ':completion:*:ssh:*' hosts off
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'

# Use caching for expensive completions
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"

# Man pages sections
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# ── fzf-tab (if available) ───────────────────────────────────
if [[ -f /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
    source /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
    zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 --color=always $realpath'
fi
