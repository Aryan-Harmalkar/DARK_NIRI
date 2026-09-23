#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  startup.zsh — Startup Sequence (loaded last)               ║
# ║  Runs startup animation and final initializations           ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Load Zsh Plugins ─────────────────────────────────────────
# Autosuggestions (fish-like ghost suggestions)
if [[ "$ZSH_ENABLE_SUGGESTIONS" == "true" ]]; then
    _zsh_load_plugin "zsh-autosuggestions" && {
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)
        ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#565f89"
        ZSH_AUTOSUGGEST_USE_ASYNC=1
    }
fi

# Syntax highlighting (fish-like command coloring — must be LAST plugin)
if [[ "$ZSH_ENABLE_SYNTAX_HIGHLIGHTING" == "true" ]]; then
    _zsh_load_plugin "zsh-syntax-highlighting" && {
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
        typeset -A ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES[command]='fg=#9ece6a'
        ZSH_HIGHLIGHT_STYLES[builtin]='fg=#7aa2f7'
        ZSH_HIGHLIGHT_STYLES[alias]='fg=#9ece6a,bold'
        ZSH_HIGHLIGHT_STYLES[function]='fg=#7dcfff'
        ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e'
        ZSH_HIGHLIGHT_STYLES[path]='fg=#73daca,underline'
        ZSH_HIGHLIGHT_STYLES[globbing]='fg=#e0af68'
        ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#e0af68'
        ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#e0af68'
        ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#7dcfff'
        ZSH_HIGHLIGHT_STYLES[comment]='fg=#565f89'
    }
fi

# ── fzf Keybindings & Completion ─────────────────────────────
if (( $+commands[fzf] )) && [[ "$ZSH_ENABLE_FZF" == "true" ]]; then
    # fzf 0.48+ uses this method
    if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh
    fi
    if [[ -f /usr/share/fzf/completion.zsh ]]; then
        source /usr/share/fzf/completion.zsh
    fi
    # Fallback for older fzf
    eval "$(fzf --zsh 2>/dev/null)" 2>/dev/null
fi

# ── Source Legacy Config (zshrc.d) ───────────────────────────
# Preserve compatibility with existing configs
for _conf in "$HOME/.config/zshrc.d"/*.zsh(N) "$HOME/.config/zshrc.d"/*.sh(N); do
    source "$_conf"
done
unset _conf

# ── Run Startup Animation ────────────────────────────────────
_zsh_startup_animation
