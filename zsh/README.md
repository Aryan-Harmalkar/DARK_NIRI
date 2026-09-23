# 🐚 DARK_NIRI Zsh Environment

A production-quality, modular, animated Zsh shell environment for Arch Linux.

Inspired by the UX philosophy of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — reimplemented as a clean, independent, portable Zsh configuration.

## ✨ Features

- **Modern Animated Prompt** — Two-line contextual prompt with Git status, venv, SSH, exit code, command timer
- **Tokyo Night Colors** — Beautiful color palette throughout the shell experience
- **Modular Architecture** — 20+ focused modules instead of one monolithic `.zshrc`
- **Startup Animation** — Fast, tasteful boot sequence (configurable: quick/full/none)
- **Git Integration** — Rich aliases, enhanced `gstat`, fast prompt info, directory enter animation
- **Smart Aliases** — `eza`/`bat`/`fd`/`rg` with automatic fallback to standard tools
- **fzf Integration** — Fuzzy history search (Ctrl+R), file search (Ctrl+F), directory jump (Alt+C)
- **Zoxide** — Smart `cd` with `z` command
- **Safety Layer** — Warnings for `rm -rf`, `dd`, `mkfs`, `chmod -R` with critical path protection
- **Package Management** — Arch-native `update`, `cleanup`, `orphans` with AUR helper detection
- **System Diagnostics** — `sysinfo`, `zsh-doctor`, `zsh-install-deps`
- **Network Helpers** — `myip`, `localip`, `ports`, `wifi`, `netinfo`
- **Feature Toggles** — Enable/disable any feature via `config.zsh`
- **Fast Startup** — Cached compinit, lazy loading, < 100ms target

## 🚀 Quick Start

```bash
cd ~/DARK_NIRI/zsh
chmod +x install.sh
./install.sh
```

Then **log out and back in** (or reboot) for Zsh to become your default shell.

## 📁 File Structure

```
zsh/
├── .zshenv              # ZDOTDIR redirector (installed to ~/.zshenv)
├── .zprofile             # Login shell setup
├── .zshrc                # Main loader — sources all modules in order
├── config.zsh            # Feature flags (toggle on/off)
├── environment.zsh       # PATH, EDITOR, locale, tool config
├── history.zsh           # History settings & fzf search
├── completion.zsh        # Tab completion with fuzzy matching
├── keybindings.zsh       # Key mappings (emacs mode, fzf, widgets)
├── aliases.zsh           # Modern tool aliases with fallbacks
├── functions.zsh         # Utility functions (extract, mkcd, backup...)
├── navigation.zsh        # Directory nav, zoxide, bookmarks
├── safety.zsh            # Dangerous command safeguards
├── git.zsh               # Git aliases & prompt info
├── prompt.zsh            # Two-line animated prompt
├── animations.zsh        # Startup animation & visual effects
├── widgets.zsh           # ZLE widgets (sudo toggle, calc...)
├── system.zsh            # sysinfo, zsh-doctor, zsh-install-deps
├── packages.zsh          # Arch package management helpers
├── network.zsh           # Network info commands
├── startup.zsh           # Plugin loading & startup animation trigger
├── install.sh            # Safe installer with backup
└── lib/
    ├── colors.zsh        # Tokyo Night color palette
    ├── helpers.zsh       # Logging, spinner, environment checks
    ├── detection.zsh     # Terminal, DE, tool detection
    └── compatibility.zsh # Plugin loader, clipboard, fallbacks
```

## ⌨️ Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+F` | Fuzzy file search |
| `Alt+C` | Fuzzy directory jump |
| `Ctrl+P/N` | History up/down |
| `Ctrl+Left/Right` | Word navigation |
| `Home/End` | Line start/end |
| `Esc Esc` | Toggle sudo prefix |
| `Ctrl+X Ctrl+E` | Edit command in $EDITOR |
| `Ctrl+Space` | Accept autosuggestion |

## 📚 Documentation

- [INSTALL.md](INSTALL.md) — Detailed installation guide
- [CONFIGURATION.md](CONFIGURATION.md) — Feature flags & customization
- [FEATURES.md](FEATURES.md) — Complete feature reference
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — Common issues & fixes

## 🔧 Quick Commands

```bash
zsh-doctor         # Environment diagnostic
zsh-install-deps   # Show/install recommended packages
zsh-config         # Edit feature flags
zsh-update         # Reload configuration
zsh-backup         # Backup current config
sysinfo            # System information
gstat              # Enhanced git status
```
