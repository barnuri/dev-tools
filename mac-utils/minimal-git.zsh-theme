# minimal-git.zsh-theme
# A minimal, fast, and informative Zsh theme with git status

# Enable colors and prompt substitution
autoload -Uz colors
colors
setopt PROMPT_SUBST
setopt EXTENDED_GLOB

# Git status function
_git_status() {
  local branch ahead behind deleted modify new merges untracked
  if [[ ! -d .git ]]; then
    echo ""
    return
  fi
  branch=$(git branch --show-current 2>/dev/null) || return
  if git rev-parse --abbrev-ref "@{u}" &>/dev/null; then
    behind=$(git rev-list --count HEAD..@{u})
    ahead=$(git rev-list --count @{u}..HEAD)
  else
    behind=0; ahead=0
  fi
  local -a statusLines
  statusLines=(${(@f)$(git status --short)})
  new=0; untracked=0; modify=0; deleted=0; merges=0
  for line in "${statusLines[@]}"; do
    if [[ $line == '??'* ]]; then ((untracked++)); continue; fi
    conflict_code="${line:0:2}"
    case $conflict_code in UU|AA|DD|AU|UA|UD|DU) ((merges++)); continue;; esac
    index_col="${line:0:1}"; worktree_col="${line:1:1}"
    [[ $index_col == 'A' ]] && ((new++))
    [[ $index_col == 'M' || $worktree_col == 'M' || $index_col == 'T' || $worktree_col == 'T' || $index_col == 'R' || $worktree_col == 'R' || $index_col == 'C' || $worktree_col == 'C' ]] && ((modify++))
    [[ $index_col == 'D' || $worktree_col == 'D' ]] && ((deleted++))
  done
  local statusDisplay=" %F{yellow}("
  if [[ -n $branch ]]; then
    statusDisplay+="%F{cyan}${branch}"
  else
    statusDisplay+="%F{red}no branch"
  fi
  if (( behind==0 && ahead==0 && new==0 && untracked==0 && modify==0 && deleted==0 && merges==0 )); then
    statusDisplay+=" %F{cyan}="
  else
    (( behind ))    && statusDisplay+=" %F{red}↓${behind}"
    (( ahead ))     && statusDisplay+=" %F{cyan}↑${ahead}"
    (( new ))       && statusDisplay+=" %F{green}+${new}"
    (( untracked )) && statusDisplay+=" %F{yellow}?${untracked}"
    (( modify ))    && statusDisplay+=" %F{cyan}±${modify}"
    (( deleted ))   && statusDisplay+=" %F{red}-${deleted}"
    (( merges ))    && statusDisplay+=" %F{magenta}!${merges}"
  fi
  statusDisplay+="%F{yellow})"
  echo "${statusDisplay}%f"
}

# Preexec: capture start time
preexec() {
  ELAPSED_START=$(date +%s.%N)
}

# Precpm: set prompt
precmd() {
  local exit_status=$?
  setopt localoptions
  if [[ -n $ELAPSED_START ]]; then
    local elapsed
    elapsed=$(printf "%.1f" "$(echo "$(date +%s.%N) - $ELAPSED_START" | bc)")
  else
    elapsed=""
  fi
  local cwdBlock="%F{green}%~%f"
  print -Pn "\e]0;Current Folder: %~\a"
  local gitBlock=""
  GIT_ENTRY=$(_git_status)
  if [[ -n $GIT_ENTRY ]]; then
    gitBlock="%F{yellow}${GIT_ENTRY}%f"
  fi
  VENV_BLOCK=""
  if [[ -n $VIRTUAL_ENV_PROMPT ]]; then
    VENV_BLOCK="%F{blue}[${VIRTUAL_ENV_PROMPT}]%f"
    alias python="$VIRTUAL_ENV/bin/python"
    alias python3="$VIRTUAL_ENV/bin/python3"
  fi
  export PS1="${cwdBlock}${gitBlock}${VENV_BLOCK} > "
  if [[ -n $elapsed ]]; then
    export RPROMPT="%F{magenta}${elapsed}s%f"
  else
    export RPROMPT=""
  fi
}
