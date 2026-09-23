# Configuration Guide

## Feature Flags

Edit `~/.config/zsh/config.zsh` (or run `zsh-config`) to toggle features:

```zsh
ZSH_ENABLE_ANIMATIONS=true          # Terminal animations
ZSH_ENABLE_GIT=true                 # Git integration & prompt info
ZSH_ENABLE_SYSTEM_INFO=true         # sysinfo, zsh-doctor commands
ZSH_ENABLE_FZF=true                 # fzf integration (Ctrl+R, Ctrl+F)
ZSH_ENABLE_ZOXIDE=true              # z/zi directory jumping
ZSH_ENABLE_TERMINAL_TITLE=true      # Dynamic terminal title
ZSH_ENABLE_SAFETY=true              # Dangerous command warnings
ZSH_ENABLE_STARTUP_ANIMATION=true   # Boot animation
ZSH_ENABLE_COMPLETION=true          # Tab completion system
ZSH_ENABLE_SUGGESTIONS=true         # Autosuggestions plugin
ZSH_ENABLE_SYNTAX_HIGHLIGHTING=true # Syntax highlighting plugin
```

Set any to `false` to disable. Changes take effect on next shell (or run `zsh-update`).

## Prompt Styles

```zsh
ZSH_PROMPT_STYLE=modern    # modern | minimal | classic
```

## Startup Animation

```zsh
ZSH_STARTUP_STYLE=quick    # quick | full | none
```

- `quick` — Single-line fast animation (~150ms)
- `full` — Multi-step initialization display (~250ms)
- `none` — No animation

## Command Timer

```zsh
ZSH_CMD_TIMER_THRESHOLD=3  # Show duration for commands taking > N seconds
```

## History Size

```zsh
ZSH_HISTSIZE=50000
ZSH_SAVEHIST=50000
```

## Environment Variables

Key environment variables set in `environment.zsh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `EDITOR` | `nvim` > `vim` > `nano` | Auto-detected editor |
| `PAGER` | `bat --plain` or `less` | Auto-detected pager |
| `FZF_DEFAULT_OPTS` | Tokyo Night colors | fzf appearance |
| `BAT_THEME` | `tokyonight_night` | bat color scheme |

## Bookmarks

Edit bookmarks in `navigation.zsh`:

```zsh
ZSH_BOOKMARKS=(
    [home]="$HOME"
    [config]="$HOME/.config"
    [projects]="$HOME/projects"
    [dots]="$HOME/DARK_NIRI"
)
```

Use: `bm <name>` to jump, `bm-add <name>` to create.

## Adding Custom Config

Place additional `.zsh` or `.sh` files in `~/.config/zshrc.d/` — they are automatically sourced (for backward compatibility with existing configs).

## Per-Module Reference

Each `.zsh` file is self-contained and documented with header comments. To understand a module, read its source — they are intentionally readable.
