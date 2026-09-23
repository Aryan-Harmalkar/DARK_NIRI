#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  install.sh — DARK_NIRI Zsh Environment Installer           ║
# ║  Safe installation with backup and validation               ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
CYAN=$'\033[36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# ── Helpers ───────────────────────────────────────────────────
info()    { printf "%s%sℹ%s %s\n" "$BLUE" "$BOLD" "$RESET" "$1"; }
success() { printf "%s%s✓%s %s\n" "$GREEN" "$BOLD" "$RESET" "$1"; }
warn()    { printf "%s%s⚠%s %s\n" "$YELLOW" "$BOLD" "$RESET" "$1"; }
error()   { printf "%s%s✗%s %s\n" "$RED" "$BOLD" "$RESET" "$1"; }

# ── Variables ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_SOURCE="${SCRIPT_DIR}"
ZSH_TARGET="$HOME/.config/zsh"
BACKUP_DIR="$HOME/.config/zsh-backup-$(date +%Y%m%d-%H%M%S)"
ZSH_BIN="$(command -v zsh 2>/dev/null)"

echo
printf "  %s%s╔══════════════════════════════════════════╗%s\n" "$BOLD" "$CYAN" "$RESET"
printf "  %s%s║   DARK_NIRI Zsh Environment Installer    ║%s\n" "$BOLD" "$CYAN" "$RESET"
printf "  %s%s╚══════════════════════════════════════════╝%s\n" "$BOLD" "$CYAN" "$RESET"
echo

# ══════════════════════════════════════════════════════════════
# Step 1: System Checks
# ══════════════════════════════════════════════════════════════
info "Step 1: System checks"

# Check OS
if [[ ! -f /etc/os-release ]]; then
    warn "Cannot detect OS. This installer is designed for Arch Linux."
fi

# Check Zsh
if [[ -z "$ZSH_BIN" ]]; then
    error "Zsh is not installed!"
    echo "  Install it with: sudo pacman -S zsh"
    exit 1
fi
success "Zsh found: $ZSH_BIN ($(zsh --version 2>/dev/null | head -1))"

# Check git
if ! command -v git &>/dev/null; then
    warn "git not found — some features will be unavailable"
else
    success "git found"
fi

echo

# ══════════════════════════════════════════════════════════════
# Step 2: Backup Existing Configuration
# ══════════════════════════════════════════════════════════════
info "Step 2: Backing up existing configuration"

BACKED_UP=false

# Backup ~/.zshrc
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
    success "Backed up ~/.zshrc → $BACKUP_DIR/.zshrc"
    BACKED_UP=true
fi

# Backup ~/.zshenv
if [[ -f "$HOME/.zshenv" && ! -L "$HOME/.zshenv" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.zshenv" "$BACKUP_DIR/.zshenv"
    success "Backed up ~/.zshenv → $BACKUP_DIR/.zshenv"
    BACKED_UP=true
fi

# Backup ~/.zprofile
if [[ -f "$HOME/.zprofile" && ! -L "$HOME/.zprofile" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.zprofile" "$BACKUP_DIR/.zprofile"
    success "Backed up ~/.zprofile → $BACKUP_DIR/.zprofile"
    BACKED_UP=true
fi

# Backup ~/.zlogin
if [[ -f "$HOME/.zlogin" && ! -L "$HOME/.zlogin" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.zlogin" "$BACKUP_DIR/.zlogin"
    success "Backed up ~/.zlogin → $BACKUP_DIR/.zlogin"
    BACKED_UP=true
fi

# Backup existing ~/.config/zsh
if [[ -d "$ZSH_TARGET" && ! -L "$ZSH_TARGET" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -a "$ZSH_TARGET" "$BACKUP_DIR/zsh-config"
    success "Backed up ~/.config/zsh/ → $BACKUP_DIR/zsh-config/"
    BACKED_UP=true
fi

if [[ "$BACKED_UP" == "false" ]]; then
    info "No existing configuration to back up"
fi

echo

# ══════════════════════════════════════════════════════════════
# Step 3: Install Configuration
# ══════════════════════════════════════════════════════════════
info "Step 3: Installing Zsh configuration"

# Create ~/.config if needed
mkdir -p "$HOME/.config"

# Remove existing symlink or directory at target
if [[ -L "$ZSH_TARGET" ]]; then
    rm "$ZSH_TARGET"
elif [[ -d "$ZSH_TARGET" ]]; then
    # Already backed up above
    rm -rf "$ZSH_TARGET"
fi

# Symlink zsh config directory
ln -sf "$ZSH_SOURCE" "$ZSH_TARGET"
success "Linked: $ZSH_TARGET → $ZSH_SOURCE"

# Install ~/.zshenv (the ZDOTDIR redirector)
# This is a tiny file, not a symlink, so it survives independently
cat > "$HOME/.zshenv" << 'EOF'
# DARK_NIRI Zsh Environment — ZDOTDIR redirector
# This file tells zsh to look for config in ~/.config/zsh/
export ZDOTDIR="$HOME/.config/zsh"

# Source the actual .zshenv from ZDOTDIR
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
success "Created ~/.zshenv (ZDOTDIR redirector)"

# Remove old ~/.zshrc (backed up already) — ZDOTDIR handles everything now
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    rm "$HOME/.zshrc"
    success "Removed old ~/.zshrc (now handled by ZDOTDIR)"
fi

# Create required state directories
mkdir -p "$HOME/.local/state/zsh"
mkdir -p "$HOME/.cache/zsh"

echo

# ══════════════════════════════════════════════════════════════
# Step 4: Validate Configuration
# ══════════════════════════════════════════════════════════════
info "Step 4: Validating configuration"

# Syntax check
if zsh -n "$ZSH_TARGET/.zshrc" 2>/dev/null; then
    success ".zshrc syntax is valid"
else
    warn ".zshrc has syntax issues — shell will still start but check errors"
fi

# Check module files exist
local_modules=(config.zsh lib/colors.zsh lib/helpers.zsh lib/detection.zsh
               lib/compatibility.zsh environment.zsh history.zsh completion.zsh
               keybindings.zsh aliases.zsh functions.zsh navigation.zsh safety.zsh
               git.zsh prompt.zsh animations.zsh widgets.zsh system.zsh
               packages.zsh network.zsh startup.zsh)
missing=0
for mod in "${local_modules[@]}"; do
    if [[ ! -f "$ZSH_TARGET/$mod" ]]; then
        warn "Missing module: $mod"
        ((missing++))
    fi
done
if [[ $missing -eq 0 ]]; then
    success "All ${#local_modules[@]} modules present"
fi

echo

# ══════════════════════════════════════════════════════════════
# Step 5: Configure Login Shell
# ══════════════════════════════════════════════════════════════
info "Step 5: Setting Zsh as login shell"

# Check if zsh is in /etc/shells
if ! grep -q "^${ZSH_BIN}$" /etc/shells 2>/dev/null; then
    warn "Zsh not found in /etc/shells"
    echo "  Adding it now (requires sudo)..."
    echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
    success "Added $ZSH_BIN to /etc/shells"
else
    success "Zsh is already in /etc/shells"
fi

# Change login shell
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" == "$ZSH_BIN" ]]; then
    success "Login shell is already Zsh"
else
    info "Changing login shell from $CURRENT_SHELL to $ZSH_BIN"
    chsh -s "$ZSH_BIN"
    if [[ $? -eq 0 ]]; then
        success "Login shell changed to $ZSH_BIN"
    else
        error "Failed to change login shell"
        echo "  Try manually: chsh -s $ZSH_BIN"
    fi
fi

echo

# ══════════════════════════════════════════════════════════════
# Step 6: Summary
# ══════════════════════════════════════════════════════════════
printf "  %s%s╔══════════════════════════════════════════╗%s\n" "$BOLD" "$GREEN" "$RESET"
printf "  %s%s║          Installation Complete!           ║%s\n" "$BOLD" "$GREEN" "$RESET"
printf "  %s%s╚══════════════════════════════════════════╝%s\n" "$BOLD" "$GREEN" "$RESET"
echo

echo "  ${BOLD}What was done:${RESET}"
echo "  • Zsh configuration installed to $ZSH_TARGET"
echo "  • ZDOTDIR set via ~/.zshenv"
echo "  • Login shell set to $ZSH_BIN"
if [[ "$BACKED_UP" == "true" ]]; then
    echo "  • Previous config backed up to $BACKUP_DIR"
fi
echo
echo "  ${BOLD}What to do next:${RESET}"
echo "  ${YELLOW}1.${RESET} Log out and log back in (or reboot)"
echo "     This activates Zsh as your default login shell."
echo
echo "  ${YELLOW}2.${RESET} Or start Zsh now in this terminal:"
echo "     ${DIM}zsh${RESET}"
echo
echo "  ${YELLOW}3.${RESET} Verify after reboot:"
echo "     ${DIM}echo \$SHELL       # should show $ZSH_BIN${RESET}"
echo "     ${DIM}ps -p \$\$ -o comm= # should show zsh${RESET}"
echo
echo "  ${YELLOW}4.${RESET} Run diagnostics:"
echo "     ${DIM}zsh-doctor${RESET}"
echo
echo "  ${YELLOW}5.${RESET} Customize:"
echo "     ${DIM}zsh-config         # edit feature flags${RESET}"
echo "     ${DIM}zsh-install-deps   # check optional tools${RESET}"
echo
if [[ "$BACKED_UP" == "true" ]]; then
    echo "  ${BOLD}To restore previous config:${RESET}"
    echo "     ${DIM}rm ~/.zshenv && rm ~/.config/zsh${RESET}"
    echo "     ${DIM}cp $BACKUP_DIR/.zshrc ~/  # if applicable${RESET}"
    echo
fi
