#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  aliases.zsh — Modern Command Aliases with Safe Fallbacks   ║
# ╚══════════════════════════════════════════════════════════════╝

# ── eza / ls ──────────────────────────────────────────────────
if (( $+commands[eza] )); then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --group-directories-first --git'
    alias la='eza -lah --icons --group-directories-first --git'
    alias lt='eza --tree --icons --level=3 --group-directories-first'
    alias l='eza -1 --icons --group-directories-first'
    alias lsd='eza -D --icons'
    alias lsf='eza -f --icons'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -lh'
    alias la='ls -lAh'
    alias l='ls -1'
fi

# ── bat / cat ─────────────────────────────────────────────────
if (( $+commands[bat] )); then
    alias cat='bat --paging=never'
    alias catp='bat --plain --paging=never'
    alias catl='bat --paging=always'
else
    alias cat='cat'
fi

# ── fd / find ─────────────────────────────────────────────────
if (( $+commands[fd] )); then
    alias find='fd'
fi

# ── ripgrep / grep ────────────────────────────────────────────
if (( $+commands[rg] )); then
    alias grep='rg'
else
    alias grep='grep --color=auto'
fi
alias egrep='grep -E'
alias fgrep='grep -F'

# ── dust / du ─────────────────────────────────────────────────
if (( $+commands[dust] )); then
    alias du='dust'
fi

# ── duf / df ──────────────────────────────────────────────────
if (( $+commands[duf] )); then
    alias df='duf'
fi

# ── delta / diff ─────────────────────────────────────────────
if (( $+commands[delta] )); then
    alias diff='delta'
fi

# ── btop / top ────────────────────────────────────────────────
if (( $+commands[btop] )); then
    alias top='btop'
    alias htop='btop'
fi

# ── General Aliases ───────────────────────────────────────────
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias ln='ln -iv'
alias mkdir='mkdir -pv'
alias chmod='chmod -v'
alias chown='chown -v'

# ── Directory Shortcuts ───────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# ── Colorize ──────────────────────────────────────────────────
alias ip='ip -color=auto'
alias dmesg='dmesg --color=auto'

# ── Quick Edit ────────────────────────────────────────────────
alias e='${EDITOR:-nano}'
alias zshconfig='${EDITOR:-nano} ${ZDOTDIR:-$HOME/.config/zsh}/.zshrc'
alias zshreload='exec zsh'

# ── System ────────────────────────────────────────────────────
alias q='exit'
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'

# ── Sudo Shortcuts ───────────────────────────────────────────
alias please='sudo !!'
alias svim='sudo ${EDITOR:-vim}'

# ── Archives ──────────────────────────────────────────────────
alias tarls='tar -tvf'
alias untar='tar -xvf'

# ── Clipboard ─────────────────────────────────────────────────
if (( $+commands[wl-copy] )); then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
fi

# ── Quick Disk Usage ──────────────────────────────────────────
alias biggest='du -sh ./* 2>/dev/null | sort -rh | head -20'
alias usage='df -h --total 2>/dev/null | tail -1'

# ── Networking ────────────────────────────────────────────────
alias ping='ping -c 5'
alias wget='wget -c'

# ── Process ───────────────────────────────────────────────────
alias psg='ps aux | grep -v grep | grep -i'
alias psmem='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3 | head -10'
