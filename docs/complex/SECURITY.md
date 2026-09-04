# 🔒 Security Audit & Privilege Boundaries

This document audits security boundaries, shell executions, and credential handling across Dark Niri.

---

## 1. Security Audit Findings

### 1.1 Sudo Password Handling in `quickshell/shutdown.sh`
- **Behavior**: Prompts for password via `rofi -dmenu -password`.
- **Finding**: Password is piped into `sudo -S shutdown -h now`.
- **Recommendation**: Standard users should prefer `systemctl poweroff` which uses polkit rather than entering sudo passwords via dmenu.

### 1.2 Shell Command Execution via `Process`
- **Behavior**: QuickShell uses `Quickshell.execDetached` and `Process`.
- **Finding**: All commands use explicit array arguments (e.g. `["wpctl", "set-volume", ...]`) preventing shell injection vulnerabilities.

### 1.3 State Files in `/tmp/`
- **Files**: `/tmp/wps_seen.json`, `/tmp/qs_dismissed.json`, `/tmp/sysinfo_net.tmp`.
- **Finding**: Standard user permission isolation applies. Cleared automatically upon reboot.

### 1.4 Hardcoded Secrets Audit
- **Result**: **0 secrets found**. No API tokens, passwords, private keys, or credentials exist in the codebase.
