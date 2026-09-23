# Installation Guide

## Prerequisites

- **OS**: Arch Linux (or Arch-based distro)
- **Zsh**: Must be installed (`sudo pacman -S zsh`)
- **Git**: Required (`sudo pacman -S git`)

## Step 1: Install Zsh

```bash
sudo pacman -S zsh
```

Verify:
```bash
zsh --version
```

## Step 2: Install Optional Tools

These enhance the experience but are not required:

```bash
sudo pacman -S --needed \
    fzf eza bat fd ripgrep zoxide git-delta \
    dust duf btop jq yq \
    zsh-autosuggestions zsh-syntax-highlighting
```

## Step 3: Run the Installer

```bash
cd ~/DARK_NIRI/zsh
chmod +x install.sh
./install.sh
```

The installer will:
1. ✅ Check that Zsh is installed
2. 📦 Back up your existing `.zshrc`, `.zshenv`, `.zprofile`, `.zlogin`
3. 🔗 Symlink `~/.config/zsh` → the repo's `zsh/` directory
4. 📝 Create `~/.zshenv` with `ZDOTDIR` redirector
5. 🐚 Add Zsh to `/etc/shells` if needed
6. 🔄 Set Zsh as your login shell via `chsh`

## Step 4: Activate

**Log out and log back in** (or reboot) for the login shell change to take effect.

Alternatively, test immediately:
```bash
zsh
```

## Step 5: Verify

```bash
echo $SHELL          # Should show /usr/bin/zsh
ps -p $$ -o comm=    # Should show zsh
zsh-doctor           # Run diagnostics
```

## How Login Shell Works

The Linux login system uses `/etc/passwd` to determine each user's shell. When you run `chsh -s /usr/bin/zsh`, it changes that entry. On next login (GUI login, TTY, or SSH), the system starts Zsh directly — no `exec zsh` hack needed.

**File loading order:**
1. `/etc/zsh/zshenv` → system-wide
2. `~/.zshenv` → sets `ZDOTDIR=$HOME/.config/zsh`
3. `~/.config/zsh/.zshenv` → (ZDOTDIR's .zshenv)
4. `~/.config/zsh/.zprofile` → (login shells only)
5. `~/.config/zsh/.zshrc` → (interactive shells only)

## Uninstalling

```bash
# Restore previous shell
chsh -s /bin/bash

# Remove config
rm ~/.zshenv
rm ~/.config/zsh     # removes symlink only

# Restore backup (if created)
ls ~/.config/zsh-backup-*
```

## Updating

Since the config is symlinked to the repo, just `git pull`:

```bash
cd ~/DARK_NIRI
git pull
```

Changes take effect on next shell launch, or run `zsh-update`.
