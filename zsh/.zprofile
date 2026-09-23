#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  .zprofile — Login Shell Setup                               ║
# ║  Sourced only for LOGIN shells (once per session)           ║
# ╚══════════════════════════════════════════════════════════════╝

# This file is intentionally minimal. Environment variables are
# set in environment.zsh (sourced by .zshrc for interactive shells).

# ── Ensure XDG dirs exist ─────────────────────────────────────
[[ -d "$HOME/.local/bin" ]]   || mkdir -p "$HOME/.local/bin"
[[ -d "$HOME/.local/share" ]] || mkdir -p "$HOME/.local/share"
[[ -d "$HOME/.local/state" ]] || mkdir -p "$HOME/.local/state"
[[ -d "$HOME/.cache" ]]       || mkdir -p "$HOME/.cache"
