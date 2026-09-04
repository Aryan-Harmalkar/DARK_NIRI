# ❓ Common Problems & Easy Fixes

Quick answers and copy-paste commands for everyday issues.

---

## 1. The Top Bar Didn't Show Up
**Cause**: QuickShell isn't installed or crashed.
**Fix**:
1. Check if `quickshell` is installed:
   ```bash
   yay -S quickshell-git
   ```
2. Restart the bar manually:
   ```bash
   killall qs; qs -d -p ~/DARK_NIRI/quickshell/shell.qml &
   ```

---

## 2. No Sound / Volume Keys Don't Work
**Cause**: WirePlumber or PipeWire audio service is paused.
**Fix**:
Restart your audio service:
```bash
systemctl --user restart pipewire wireplumber
```

---

## 3. Icons Look Like Missing Squares / Boxes
**Cause**: The icon font is missing.
**Fix**:
Install the Nerd Fonts icon package:
```bash
sudo pacman -S ttf-nerd-fonts-symbols ttf-inter
```

---

## 4. Wi-Fi Won't Connect or Shows Disconnected
**Cause**: NetworkManager service is not running.
**Fix**:
Start NetworkManager:
```bash
sudo systemctl enable --now NetworkManager
```

---

## 5. Bluetooth Is Not Working
**Cause**: Bluetooth daemon is stopped or blocked by rfkill.
**Fix**:
```bash
sudo systemctl enable --now bluetooth
sudo rfkill unblock bluetooth
```

---

## 6. How to Update Dark Niri to the Latest Version
```bash
cd ~/DARK_NIRI
git pull
./deploy.sh
```

---

## 7. How to Completely Uninstall and Restore Previous Configs
```bash
cd ~/DARK_NIRI
./uninstall.sh
```
This cleanly removes all symlinks and restores your previous `.config` backups automatically!
