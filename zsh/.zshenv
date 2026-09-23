# ╔══════════════════════════════════════════════════════════════╗
# ║  .zshenv — Zsh Environment (loaded for ALL zsh instances)   ║
# ║  This file lives in ZDOTDIR (~/.config/zsh/)                ║
# ║  The ~/.zshenv redirector sets ZDOTDIR to point here        ║
# ╚══════════════════════════════════════════════════════════════╝

# Ensure ZDOTDIR is set (in case we're sourced directly)
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
