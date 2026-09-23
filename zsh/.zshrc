#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  .zshrc — Main Interactive Shell Configuration              ║
# ║  Part of DARK_NIRI Zsh Environment                          ║
# ║  Modular loader — sources all modules in correct order      ║
# ╚══════════════════════════════════════════════════════════════╝

# Only run for interactive shells
[[ -o interactive ]] || return

# ── Resolve config directory ──────────────────────────────────
typeset -g ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}"

# ── Error-safe module loader ─────────────────────────────────
_zsh_load_module() {
    local module="$1"
    local mod_path="${ZSH_CONFIG_DIR}/${module}"
    if [[ -f "$mod_path" ]]; then
        source "$mod_path" 2>/dev/null || {
            print -P "%F{red}Error loading: ${module}%f" >&2
        }
    fi
}

# ══════════════════════════════════════════════════════════════
#  Module Loading Order
#  ───────────────────
#  1. Config & Library (foundation)
#  2. Shell Settings (env, history, completion, keys)
#  3. User Features (aliases, functions, navigation, safety)
#  4. Integrations (git, prompt, animations, widgets)
#  5. System Tools (sysinfo, packages, network)
#  6. Startup (plugins, animation — ALWAYS LAST)
# ══════════════════════════════════════════════════════════════

# ── Phase 1: Foundation ──────────────────────────────────────
_zsh_load_module "config.zsh"
_zsh_load_module "lib/colors.zsh"
_zsh_load_module "lib/helpers.zsh"
_zsh_load_module "lib/detection.zsh"
_zsh_load_module "lib/compatibility.zsh"

# ── Phase 2: Shell Settings ──────────────────────────────────
_zsh_load_module "environment.zsh"
_zsh_load_module "history.zsh"
_zsh_load_module "completion.zsh"
_zsh_load_module "keybindings.zsh"

# ── Phase 3: User Features ──────────────────────────────────
_zsh_load_module "aliases.zsh"
_zsh_load_module "functions.zsh"
_zsh_load_module "navigation.zsh"
_zsh_load_module "safety.zsh"

# ── Phase 4: Integrations ───────────────────────────────────
_zsh_load_module "git.zsh"
_zsh_load_module "prompt.zsh"
_zsh_load_module "animations.zsh"
_zsh_load_module "widgets.zsh"

# ── Phase 5: System Tools ───────────────────────────────────
_zsh_load_module "system.zsh"
_zsh_load_module "packages.zsh"
_zsh_load_module "network.zsh"

# ── Phase 6: Startup (MUST BE LAST) ─────────────────────────
_zsh_load_module "startup.zsh"

# ── Cleanup ──────────────────────────────────────────────────
unfunction _zsh_load_module 2>/dev/null
