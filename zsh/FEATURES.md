# Feature Reference

## Prompt

The prompt is a two-line contextual display:

```
╭─ ~/projects/DarkWizard  main +2 ~1  venv  3.2s
╰─❯
```

**Contextual elements** (only appear when relevant):
- 📁 **Directory** — shortened if path > 40 chars
- 🌿 **Git branch** — branch name in teal
- 📊 **Git status** — `+N` staged, `~N` modified, `…N` untracked, `↑N ↓N` ahead/behind
- 🐍 **Python venv** — virtual environment name
- ⎈ **K8s context** — Kubernetes context (if kubectl installed)
- ⏱ **Duration** — command execution time (> 3s threshold)
- ❌ **Exit code** — shown in red when non-zero
- 🔑 **SSH** — `user@host` shown in SSH sessions
- 🔴 **Root** — red `user@host` and `#` prompt when root

## Animations

### Startup Animation
- **quick** — Single-line dot progression, ~150ms
- **full** — Multi-step initialization display
- **none** — Disabled
- Skipped in SSH, nested shells, and non-interactive mode

### Git Directory Animation
- Brief repo name + branch flash when entering a new Git repository

### Spinner
- Available via `_zsh_spinner_start "message"` / `_zsh_spinner_stop`
- Unicode Braille spinner with ASCII fallback

## Aliases

### Modern Replacements (auto-fallback)
| Alias | With tool | Without |
|-------|-----------|---------|
| `ls` | `eza --icons` | `ls --color` |
| `ll` | `eza -lh --git` | `ls -lh` |
| `cat` | `bat --paging=never` | `cat` |
| `grep` | `rg` | `grep --color` |
| `du` | `dust` | `du` |
| `df` | `duf` | `df` |
| `diff` | `delta` | `diff` |
| `top` | `btop` | `top` |

### Safety Aliases
- `cp`, `mv` — interactive (`-iv`)
- `rm` — confirmation for bulk (`-I`), warning for `-rf`
- `mkdir` — verbose, create parents (`-pv`)

### Shortcuts
| Alias | Action |
|-------|--------|
| `..` / `...` / `....` | Navigate up directories |
| `-` | Previous directory |
| `c` | Clear screen |
| `e` | Open `$EDITOR` |
| `q` | Exit shell |
| `path` | Print PATH entries |

## Functions

| Function | Description |
|----------|-------------|
| `mkcd <dir>` | Create directory and cd into it |
| `extract <file>` | Extract any archive format |
| `backup <file>` | Create timestamped backup |
| `weather [city]` | Weather forecast |
| `cheat <cmd>` | Command cheat sheet |
| `open [file]` | Open with system default |
| `serve [port]` | Quick HTTP server |
| `up [N]` | Go up N directories |
| `tre [depth]` | Tree view with eza/tree |
| `sizeof [path]` | Directory/file size |
| `countdown [secs]` | Countdown timer |
| `json` | Pretty-print JSON |
| `calc <expr>` | Quick calculator |
| `note [text]` | Quick note taking |

## Git Integration

### Aliases
| Alias | Command |
|-------|---------|
| `gs` | `git status -sb` |
| `ga` | `git add` |
| `gc` | `git commit -v` |
| `gcm` | `git commit -m` |
| `gca` | `git commit --amend` |
| `gp` | `git push` |
| `gpl` | `git pull --rebase` |
| `gco` | `git checkout` |
| `gb` | `git branch -vv` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `glog` | `git log --oneline --graph` |
| `gwip` | Quick WIP commit |

### Functions
| Function | Description |
|----------|-------------|
| `gstat` | Enhanced visual git status |
| `git-recent` | Recent branches by date |
| `git-who` | Top contributors |
| `git-undo` | Undo last commit (safe) |

## Navigation

| Feature | Description |
|---------|-------------|
| `z <query>` | Zoxide smart jump |
| `zi` | Zoxide interactive |
| `bm [name]` | Bookmark jump / list |
| `bm-add <name>` | Create bookmark |
| `fcd` | Fuzzy directory browser |
| `recent` | Recent directories (fzf) |
| `d` | Directory stack |
| `1`-`9` | Jump to stack position |

## Package Management

| Command | Action |
|---------|--------|
| `update` | Full system update (paru/yay/pacman) |
| `installpkg <pkg>` | Install package |
| `removepkg <pkg>` | Remove with confirmation |
| `searchpkg <query>` | Search packages |
| `orphans` | Find/remove orphaned packages |
| `cleanup` | Clean package cache |
| `pkginfo <pkg>` | Package info |
| `whichpkg <file>` | Which package owns file |
| `pkg-count` | Package statistics |

## Network

| Command | Description |
|---------|-------------|
| `myip` | Public IP address |
| `localip` | Local IP addresses |
| `ports` | Listening ports |
| `wifi [cmd]` | WiFi management |
| `netinfo` | Full network info |
| `ping-test` | Connectivity check |
| `speedtest` | Download speed test |

## System

| Command | Description |
|---------|-------------|
| `sysinfo` | System overview |
| `zsh-doctor` | Shell diagnostic |
| `zsh-install-deps` | Show recommended packages |
| `zsh-config` | Edit feature flags |
| `zsh-update` | Reload configuration |
| `zsh-backup` | Backup configuration |

## Widgets

| Key | Widget |
|-----|--------|
| `Esc Esc` | Toggle `sudo` prefix |
| `.` (after `..`) | Smart expand to `../..` |
| `Ctrl+X Ctrl+C` | Copy line to clipboard |
| `Ctrl+X =` | Inline calculator |
| `Alt+H` | Show man page for current command |

## Safety

Protected commands with confirmation prompts:
- `rm -rf` — blocked on `/`, `/home`, `/usr`, `/etc`, `$HOME`
- `dd` — always requires confirmation
- `mkfs` — always requires confirmation
- `chmod -R` / `chown -R` — warns on recursive mode
- `NO_CLOBBER` — prevents `>` overwriting existing files (use `>|` to override)
- `CORRECT` / `CORRECT_ALL` — typo correction suggestions
