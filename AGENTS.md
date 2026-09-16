# Antigravity Rules for DARK_NIRI

## 1. Git Workflow & Push Reminder
- **DO NOT** execute `git push` automatically under any circumstances.
- At the end of every completed request or task, always remind the user to push their changes manually (e.g. `git push` or `git add . && git commit -m "..." && git push`).

## 2. Documentation Updates
- Whenever any dotfiles, configs (`niri/`, `quickshell/`, `rofi/`, `mako/`, etc.), scripts, or components are added, modified, or removed:
  - Immediately update the relevant documentation (`README.md`, `keybindings-docs.md`, or docs in `docs/`).
  - Keep features, descriptions, file trees, dependencies, and keybindings accurately documented and in sync with the codebase.

## 3. Session Edit Logs
- At the end of every completed task or request, generate a timestamped markdown file inside `Edited/` to document the session's modifications.
- **Directory structure:**
  ```
  Edited/
  ├── changes/        # Refactors, renames, restructures, config tweaks
  ├── fixes/          # Bug fixes, crash fixes, broken behavior corrections
  ├── updates/        # Dependency updates, version bumps, improvements to existing features
  └── new-features/   # Entirely new functionality, scripts, components, or integrations
  ```
- **File naming:** `YYYY-MM-DD_HH-MM-SS.md` (e.g. `2026-09-13_20-48-00.md`), using the current local time.
- **File format:**
  ```markdown
  # Session: <brief title>

  **Date:** YYYY-MM-DD HH:MM:SS
  **Category:** changes | fixes | updates | new-features

  ## Modifications
  - <concise bullet describing what was changed and why>
  - <concise bullet describing what was changed and why>

  ## Files Modified
  - `path/to/file1`
  - `path/to/file2`
  ```
- Use clear, concise bullet points and maintain consistent formatting across all files.
- If a session spans multiple categories, create a file in the **primary** category and cross-reference the others in the body.
