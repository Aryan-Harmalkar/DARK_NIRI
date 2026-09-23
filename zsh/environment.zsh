#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  environment.zsh — Environment Variables & PATH              ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Editor ────────────────────────────────────────────────────
if (( $+commands[nvim] )); then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif (( $+commands[vim] )); then
    export EDITOR="vim"
    export VISUAL="vim"
else
    export EDITOR="nano"
    export VISUAL="nano"
fi

# ── Pager ─────────────────────────────────────────────────────
if (( $+commands[bat] )); then
    export PAGER="bat --plain"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
else
    export PAGER="less"
fi
export LESS="-R -F -X -i -M -S --mouse"

# ── Locale ────────────────────────────────────────────────────
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ── XDG Base Directories ─────────────────────────────────────
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ── PATH (add local bins if not present) ──────────────────────
typeset -U path  # deduplicate PATH entries
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
    "$HOME/.npm-global/bin"
    $path
)

# ── Tool-Specific Config ─────────────────────────────────────
# fzf
if (( $+commands[fzf] )); then
    export FZF_DEFAULT_OPTS="
        --height 40% --layout=reverse --border rounded
        --color=bg+:#283457,bg:#1a1b26,spinner:#7dcfff,hl:#7aa2f7
        --color=fg:#c0caf5,header:#7aa2f7,info:#e0af68,pointer:#f7768e
        --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7dcfff
        --prompt='❯ ' --pointer='▸' --marker='✓'
    "
    if (( $+commands[fd] )); then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
    fi
fi

# bat
if (( $+commands[bat] )); then
    export BAT_THEME="${BAT_THEME:-tokyonight_night}"
fi

# ripgrep
if (( $+commands[rg] )); then
    export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
fi

# ── GPG TTY ───────────────────────────────────────────────────
if [[ -t 0 ]]; then
    export GPG_TTY=$(tty)
fi

# ── Rust ──────────────────────────────────────────────────────
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env" 2>/dev/null
:  # ensure clean exit status
