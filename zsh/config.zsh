#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  config.zsh — Feature Flags & User Configuration            ║
# ║  Toggle features on/off without deleting files               ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Core Features ─────────────────────────────────────────────
ZSH_ENABLE_ANIMATIONS="${ZSH_ENABLE_ANIMATIONS:-true}"
ZSH_ENABLE_GIT="${ZSH_ENABLE_GIT:-true}"
ZSH_ENABLE_SYSTEM_INFO="${ZSH_ENABLE_SYSTEM_INFO:-true}"
ZSH_ENABLE_FZF="${ZSH_ENABLE_FZF:-true}"
ZSH_ENABLE_ZOXIDE="${ZSH_ENABLE_ZOXIDE:-true}"
ZSH_ENABLE_TERMINAL_TITLE="${ZSH_ENABLE_TERMINAL_TITLE:-true}"
ZSH_ENABLE_SAFETY="${ZSH_ENABLE_SAFETY:-true}"
ZSH_ENABLE_STARTUP_ANIMATION="${ZSH_ENABLE_STARTUP_ANIMATION:-true}"
ZSH_ENABLE_COMPLETION="${ZSH_ENABLE_COMPLETION:-true}"
ZSH_ENABLE_SUGGESTIONS="${ZSH_ENABLE_SUGGESTIONS:-true}"
ZSH_ENABLE_SYNTAX_HIGHLIGHTING="${ZSH_ENABLE_SYNTAX_HIGHLIGHTING:-true}"

# ── Prompt Settings ───────────────────────────────────────────
ZSH_PROMPT_STYLE="${ZSH_PROMPT_STYLE:-modern}"    # modern | minimal | classic
ZSH_PROMPT_GIT_ASYNC="${ZSH_PROMPT_GIT_ASYNC:-true}"
ZSH_CMD_TIMER_THRESHOLD="${ZSH_CMD_TIMER_THRESHOLD:-3}"  # seconds before showing duration

# ── Startup Animation ────────────────────────────────────────
ZSH_STARTUP_STYLE="${ZSH_STARTUP_STYLE:-quick}"   # quick | full | none

# ── History ───────────────────────────────────────────────────
ZSH_HISTSIZE="${ZSH_HISTSIZE:-50000}"
ZSH_SAVEHIST="${ZSH_SAVEHIST:-50000}"

# ── Path to this config (auto-detected) ──────────────────────
ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}"
