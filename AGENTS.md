# Antigravity Rules for DARK_NIRI

## 1. Git Workflow & Push Reminder
- **DO NOT** execute `git push` automatically under any circumstances.
- At the end of every completed request or task, always remind the user to push their changes manually (e.g. `git push` or `git add . && git commit -m "..." && git push`).

## 2. Documentation Updates
- Whenever any dotfiles, configs (`niri/`, `quickshell/`, `rofi/`, `mako/`, etc.), scripts, or components are added, modified, or removed:
  - Immediately update the relevant documentation (`README.md`, `keybindings-docs.md`, or docs in `docs/`).
  - Keep features, descriptions, file trees, dependencies, and keybindings accurately documented and in sync with the codebase.
