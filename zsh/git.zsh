#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  git.zsh — Advanced Git Integration & Helpers               ║
# ╚══════════════════════════════════════════════════════════════╝

[[ "$ZSH_ENABLE_GIT" == "true" ]] || return 0
(( $+commands[git] )) || return 0

# ── Git Aliases ───────────────────────────────────────────────
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull --rebase'
alias gf='git fetch --all --prune'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch -vv'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gd='git diff'
alias gds='git diff --staged'
alias gdt='git difftool'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gm='git merge'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gcp='git cherry-pick'
alias glog='git log --oneline --graph --decorate -20'
alias gloga='git log --oneline --graph --decorate --all -30'
alias glogp='git log --pretty=format:"%C(yellow)%h%Creset %C(blue)%ad%Creset %C(green)%an%Creset %s%C(red)%d%Creset" --date=short -20'
alias gwip='git add -A && git commit -m "WIP: work in progress [skip ci]"'
alias gunwip='git log -1 --pretty=%B | grep -q "WIP:" && git reset HEAD~1'
alias gclean='git clean -fd'
alias greset='git reset --hard HEAD'
alias gtags='git tag -l --sort=-v:refname | head -20'

# ── Git Status (enhanced) ────────────────────────────────────
gstat() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        _zsh_warning "Not in a Git repository"
        return 1
    fi

    local branch=$(git branch --show-current 2>/dev/null)
    local remote=$(git rev-parse --abbrev-ref @{u} 2>/dev/null)

    echo
    printf "  %s%s Branch:%s %s\n" "$C_BOLD" "$C_BLUE" "$C_RESET" "${branch:-detached}"

    if [[ -n "$remote" ]]; then
        local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
        local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
        printf "  %s%s Remote:%s %s" "$C_BOLD" "$C_CYAN" "$C_RESET" "$remote"
        [[ "$ahead" -gt 0 ]] && printf " %s↑%s%s" "$C_GREEN" "$ahead" "$C_RESET"
        [[ "$behind" -gt 0 ]] && printf " %s↓%s%s" "$C_RED" "$behind" "$C_RESET"
        echo
    fi

    local staged=$(git diff --cached --numstat 2>/dev/null | wc -l)
    local modified=$(git diff --numstat 2>/dev/null | wc -l)
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    local conflicts=$(git diff --name-only --diff-filter=U 2>/dev/null | wc -l)

    echo
    [[ "$staged" -gt 0 ]]    && printf "  %s✓ %d staged%s\n" "$C_GREEN" "$staged" "$C_RESET"
    [[ "$modified" -gt 0 ]]  && printf "  %s● %d modified%s\n" "$C_YELLOW" "$modified" "$C_RESET"
    [[ "$untracked" -gt 0 ]] && printf "  %s… %d untracked%s\n" "$C_GRAY" "$untracked" "$C_RESET"
    [[ "$conflicts" -gt 0 ]] && printf "  %s✗ %d conflicts%s\n" "$C_RED" "$conflicts" "$C_RESET"

    if (( staged + modified + untracked + conflicts == 0 )); then
        printf "  %s✓ Clean working tree%s\n" "$C_GREEN" "$C_RESET"
    fi
    echo
}

# ── Git Prompt Info (fast, for prompt.zsh) ────────────────────
# Returns: branch, dirty status, ahead/behind — designed to be fast
_zsh_git_prompt_info() {
    # Quick check: are we in a git repo?
    local gitdir
    gitdir=$(git rev-parse --git-dir 2>/dev/null) || return

    # Branch name
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    branch=$(git describe --tags --exact-match HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null) || \
    branch="unknown"

    # Status flags (use porcelain for speed)
    local staged=0 modified=0 untracked=0 ahead=0 behind=0
    local line
    while IFS= read -r line; do
        case "$line" in
            "# branch.ab "*)
                ahead=${line#*+}; ahead=${ahead%% *}
                behind=${line#*-}; behind=${behind%% *}
                ;;
            "1 M"*|"1 A"*|"1 D"*|"1 R"*|"1 C"*)
                ((staged++))
                ;;
            "1 .M"*|"1 .D"*)
                ((modified++))
                ;;
            "? "*)
                ((untracked++))
                ;;
            "2 "*)
                # Renamed entries
                local xy="${line:2:2}"
                [[ "${xy[1]}" != "." ]] && ((staged++))
                [[ "${xy[2]}" != "." ]] && ((modified++))
                ;;
            "1 "[MADRC][MADRC]*)
                ((staged++))
                ((modified++))
                ;;
        esac
    done < <(git status --porcelain=v2 --branch 2>/dev/null)

    # Build output
    local info=" ${P_TEAL}${branch}${P_RESET}"

    local dirty=""
    (( staged > 0 ))    && dirty+="${P_GREEN}+${staged}"
    (( modified > 0 ))  && dirty+="${P_YELLOW}~${modified}"
    (( untracked > 0 )) && dirty+="${P_GRAY}…${untracked}"

    [[ -n "$dirty" ]] && info+=" ${dirty}${P_RESET}"

    (( ahead > 0 ))  && info+=" ${P_GREEN}↑${ahead}${P_RESET}"
    (( behind > 0 )) && info+=" ${P_RED}↓${behind}${P_RESET}"

    echo -n "$info"
}

# ── Git Recent Branches ──────────────────────────────────────
git-recent() {
    git for-each-ref --sort=-committerdate refs/heads/ \
        --format='%(color:yellow)%(refname:short)%(color:reset) %(color:blue)%(committerdate:relative)%(color:reset) %(subject)' \
        --count="${1:-10}"
}

# ── Git Who (contributors) ───────────────────────────────────
git-who() {
    git shortlog -sn --all --no-merges | head -"${1:-15}"
}

# ── Git Undo (safe undo last commit) ─────────────────────────
git-undo() {
    git reset --soft HEAD~1
    _zsh_success "Undid last commit (changes preserved in staging)"
}
