#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  prompt.zsh — Modern Animated Prompt (Tokyo Night)           ║
# ║  Contextual two-line prompt with git, venv, timer, SSH      ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Command Timer (preexec/precmd hooks) ──────────────────────
typeset -g _ZSH_CMD_START_TIME=0
typeset -g _ZSH_CMD_DURATION=""
typeset -g _ZSH_LAST_EXIT=0

_zsh_prompt_preexec() {
    _ZSH_CMD_START_TIME=$EPOCHSECONDS
}

_zsh_prompt_precmd() {
    _ZSH_LAST_EXIT=$?
    _ZSH_CMD_DURATION=""

    if (( _ZSH_CMD_START_TIME > 0 )); then
        local elapsed=$(( EPOCHSECONDS - _ZSH_CMD_START_TIME ))
        if (( elapsed >= ${ZSH_CMD_TIMER_THRESHOLD:-3} )); then
            _ZSH_CMD_DURATION=$(_zsh_format_duration $elapsed)
        fi
        _ZSH_CMD_START_TIME=0
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _zsh_prompt_preexec
add-zsh-hook precmd  _zsh_prompt_precmd

# ── Shorten Path ─────────────────────────────────────────────
_zsh_short_path() {
    local p="${PWD/#$HOME/~}"
    # If path is short enough, show full
    if (( ${#p} <= 40 )); then
        echo -n "$p"
        return
    fi
    # Shorten: ~/a/b/c/deep/dir → ~/a/b/…/dir
    local parts=(${(s:/:)p})
    local count=${#parts[@]}
    if (( count <= 4 )); then
        echo -n "$p"
    else
        echo -n "${parts[1]}/${parts[2]}/…/${parts[-1]}"
    fi
}

# ── Build Prompt ──────────────────────────────────────────────
_zsh_build_prompt() {
    local top_line=""
    local bot_line=""

    # ── Box drawing character ──
    local corner_tl=$(_zsh_icon "╭─" "+-")
    local corner_bl=$(_zsh_icon "╰─" "+-")
    local arrow=$(_zsh_icon "❯" ">")

    # ── Top Line ──────────────────────────────────────────────

    # Exit status indicator
    if (( _ZSH_LAST_EXIT != 0 )); then
        top_line+="${P_RED}${_ZSH_LAST_EXIT} "
    fi

    # SSH indicator
    if _zsh_is_ssh; then
        top_line+="${P_MAGENTA}%n@%m${P_RESET} "
    elif _zsh_is_root; then
        top_line+="${P_RED}%n@%m${P_RESET} "
    fi

    # Current directory
    top_line+="${P_BLUE}$(_zsh_short_path)${P_RESET}"

    # Git info (only in git repos)
    if [[ "$ZSH_ENABLE_GIT" == "true" ]] && \
       git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
        top_line+="$(_zsh_git_prompt_info)"
    fi

    # Python virtual env
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name="${VIRTUAL_ENV:t}"
        top_line+=" ${P_YELLOW}${venv_name}${P_RESET}"
    fi

    # Kubernetes context (only if kubectl exists and KUBECONFIG is set)
    if (( $+commands[kubectl] )) && [[ -n "$KUBECONFIG" || -f "$HOME/.kube/config" ]]; then
        local k8s_ctx
        k8s_ctx=$(kubectl config current-context 2>/dev/null)
        if [[ -n "$k8s_ctx" ]]; then
            top_line+=" ${P_CYAN}⎈ ${k8s_ctx}${P_RESET}"
        fi
    fi

    # Command duration
    if [[ -n "$_ZSH_CMD_DURATION" ]]; then
        top_line+=" ${P_YELLOW}${_ZSH_CMD_DURATION}${P_RESET}"
    fi

    # ── Bottom Line ───────────────────────────────────────────
    local prompt_char="$arrow"
    local prompt_color="${P_TEAL}"

    if _zsh_is_root; then
        prompt_char=$(_zsh_icon "❯" "#")
        prompt_color="${P_RED}"
    fi

    if (( _ZSH_LAST_EXIT != 0 )); then
        prompt_color="${P_RED}"
    fi

    # ── Assemble ──────────────────────────────────────────────
    PROMPT="${P_GRAY}${corner_tl}${P_RESET} ${top_line}
${P_GRAY}${corner_bl}${prompt_color}${prompt_char}${P_RESET} "

    # ── Right Prompt (minimal) ────────────────────────────────
    RPROMPT=""
}

# ── Terminal Title Hook ──────────────────────────────────────
_zsh_set_terminal_title() {
    [[ "$ZSH_ENABLE_TERMINAL_TITLE" == "true" ]] || return
    _zsh_supports_title || return

    local title="${PWD/#$HOME/~}"
    # Show command name during execution
    if [[ -n "$1" ]]; then
        title="$1 — ${title}"
    fi
    printf '\033]2;%s\007' "$title"
}

_zsh_title_preexec() {
    # Show running command in title
    local cmd="${1[(w)1]}"  # first word of command
    _zsh_set_terminal_title "$cmd"
}

_zsh_title_precmd() {
    _zsh_set_terminal_title
}

if [[ "$ZSH_ENABLE_TERMINAL_TITLE" == "true" ]]; then
    add-zsh-hook preexec _zsh_title_preexec
    add-zsh-hook precmd  _zsh_title_precmd
fi

# ── Prompt Render Hook ───────────────────────────────────────
_zsh_prompt_render() {
    _zsh_build_prompt
}

add-zsh-hook precmd _zsh_prompt_render

# ── Disable default venv prompt (we handle it ourselves) ─────
export VIRTUAL_ENV_DISABLE_PROMPT=1

# ── Initial prompt build ─────────────────────────────────────
_zsh_build_prompt
