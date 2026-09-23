# Troubleshooting

## Shell is still Bash after install

**Problem**: After running `install.sh`, opening a new terminal still shows Bash.

**Solution**: You must **log out and log back in** (or reboot). The `chsh` command changes `/etc/passwd`, which is read at login time.

Verify the change took:
```bash
getent passwd $USER | cut -d: -f7
# Should show: /usr/bin/zsh
```

## `command not found` errors on startup

**Problem**: Errors like `zsh-autosuggestions: command not found`.

**Solution**: Install the missing plugins:
```bash
sudo pacman -S zsh-autosuggestions zsh-syntax-highlighting
```

Or disable them in `config.zsh`:
```zsh
ZSH_ENABLE_SUGGESTIONS=false
ZSH_ENABLE_SYNTAX_HIGHLIGHTING=false
```

## Slow startup

**Problem**: Shell takes more than 200ms to start.

**Diagnosis**:
```bash
time zsh -i -c exit
```

**Solutions**:
1. Disable startup animation: `ZSH_ENABLE_STARTUP_ANIMATION=false`
2. Disable unused features in `config.zsh`
3. Check compinit cache: `ls ~/.cache/zsh/zcompdump`
4. Profile startup: `zsh -xvs 2>&1 | head -100`
5. Run `zsh-doctor` for analysis

## Prompt looks broken / garbled

**Problem**: Unicode characters show as boxes or `?`.

**Solutions**:
1. Install a Nerd Font: `sudo pacman -S ttf-nerd-fonts-symbols`
2. Set your terminal to use the Nerd Font
3. Ensure locale: `echo $LANG` should show `en_US.UTF-8`
4. If in TTY/SSH with limited font, the prompt auto-falls back to ASCII

## `.zshrc` has syntax errors

**Diagnosis**:
```bash
zsh -n ~/.config/zsh/.zshrc
```

**Solution**: Each module is error-isolated. If one module fails, the shell still works. Fix the syntax error in the reported file.

## Restore previous configuration

```bash
# Check your backup
ls ~/.config/zsh-backup-*/

# Restore
chsh -s /bin/bash
rm ~/.zshenv
rm ~/.config/zsh  # removes symlink
cp ~/.config/zsh-backup-*/.zshrc ~/  # restore old .zshrc
```

## `rm` keeps asking for confirmation

The safety layer adds warnings for `rm -rf`. This is intentional.

To bypass for a single command:
```bash
command rm -rf <target>
```

To disable permanently:
```zsh
# In config.zsh:
ZSH_ENABLE_SAFETY=false
```

## Smart dot expansion breaks input

The `.` key is bound to expand `..` → `../..`. If this causes issues:

Remove the binding by commenting out the `bindkey '.'` line in `widgets.zsh`.

## fzf / zoxide not working

Run `zsh-install-deps` to check what's installed. Install missing tools:
```bash
sudo pacman -S fzf zoxide
```

Or disable:
```zsh
ZSH_ENABLE_FZF=false
ZSH_ENABLE_ZOXIDE=false
```

## Bash still works normally

Entering `bash` from Zsh will start a normal Bash session. Typing `exit` returns to Zsh. There is no recursion loop — `exec zsh` is NOT used in `.bashrc`.

## Running `zsh-doctor`

This is the first command to run for any issue:
```bash
zsh-doctor
```

It checks:
- Zsh version
- Required/optional tool availability
- Plugin installation
- Config syntax
- Login shell configuration
- Startup performance
