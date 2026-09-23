#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  keybindings.zsh — Key Mappings for Emacs & Vi Modes        ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Use Emacs mode by default ─────────────────────────────────
bindkey -e

# ── Home / End / Delete ───────────────────────────────────────
bindkey '^[[H'    beginning-of-line        # Home
bindkey '^[[F'    end-of-line              # End
bindkey '^[[1~'   beginning-of-line        # Home (alt)
bindkey '^[[4~'   end-of-line              # End (alt)
bindkey '^[[3~'   delete-char              # Delete
bindkey '^[[3;5~' kill-word                # Ctrl+Delete
bindkey '^H'      backward-kill-word       # Ctrl+Backspace

# ── Word Navigation ──────────────────────────────────────────
bindkey '^[[1;5C' forward-word             # Ctrl+Right
bindkey '^[[1;5D' backward-word            # Ctrl+Left
bindkey '^[[1;3C' forward-word             # Alt+Right
bindkey '^[[1;3D' backward-word            # Alt+Left
bindkey '\ef'     forward-word             # Alt+f
bindkey '\eb'     backward-word            # Alt+b

# ── History Navigation ───────────────────────────────────────
bindkey '^P'      up-line-or-search        # Ctrl+P
bindkey '^N'      down-line-or-search      # Ctrl+N
bindkey '^[[A'    up-line-or-search        # Up arrow
bindkey '^[[B'    down-line-or-search      # Down arrow

# ── History Search ────────────────────────────────────────────
if (( $+commands[fzf] )) && [[ "$ZSH_ENABLE_FZF" == "true" ]]; then
    bindkey '^R' _fzf_history_search 2>/dev/null || bindkey '^R' history-incremental-search-backward
else
    bindkey '^R' history-incremental-search-backward
fi
bindkey '^S' history-incremental-search-forward

# ── Useful Shortcuts ─────────────────────────────────────────
bindkey '^U'  kill-whole-line              # Ctrl+U: clear line
bindkey '^K'  kill-line                    # Ctrl+K: kill to end
bindkey '^A'  beginning-of-line            # Ctrl+A: go to start
bindkey '^E'  end-of-line                  # Ctrl+E: go to end
bindkey '^W'  backward-kill-word           # Ctrl+W: delete word back
bindkey '\ed' kill-word                    # Alt+D: delete word fwd
bindkey '^Y'  yank                         # Ctrl+Y: paste killed text
bindkey '^L'  clear-screen                 # Ctrl+L: clear screen
bindkey '^Z'  undo                         # Ctrl+Z: undo

# ── fzf File Search Widget ────────────────────────────────────
if (( $+commands[fzf] )) && [[ "$ZSH_ENABLE_FZF" == "true" ]]; then
    _fzf_file_search() {
        local cmd="fd --type f --hidden --follow --exclude .git 2>/dev/null || find . -type f 2>/dev/null"
        local selected
        selected=$(eval "$cmd" | fzf --height=40% --layout=reverse --border --prompt="Files ❯ ")
        if [[ -n "$selected" ]]; then
            LBUFFER+="$selected"
        fi
        zle reset-prompt
    }
    zle -N _fzf_file_search
    bindkey '^F' _fzf_file_search          # Ctrl+F: fuzzy file search

    _fzf_cd_search() {
        local cmd="fd --type d --hidden --follow --exclude .git 2>/dev/null || find . -type d 2>/dev/null"
        local selected
        selected=$(eval "$cmd" | fzf --height=40% --layout=reverse --border --prompt="Dirs ❯ " \
                   --preview 'eza -1 --color=always {} 2>/dev/null || ls -1 --color=always {}')
        if [[ -n "$selected" ]]; then
            cd "$selected"
        fi
        zle reset-prompt
    }
    zle -N _fzf_cd_search
    bindkey '\ec' _fzf_cd_search           # Alt+C: fuzzy cd
fi

# ── Accept Autosuggestion ─────────────────────────────────────
bindkey '^ '  autosuggest-accept 2>/dev/null   # Ctrl+Space
bindkey '^[[Z' reverse-menu-complete           # Shift+Tab

# ── Edit Command in $EDITOR ──────────────────────────────────
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line               # Ctrl+X Ctrl+E
