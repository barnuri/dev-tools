# Setup: enable color expansion and prompt substitution

autoload -Uz colors
colors
setopt PROMPT_SUBST
setopt EXTENDED_GLOB

# ====== Begin gitStatus zsh port of PS gitStatus() ======
gitStatus() {
  local branch ahead behind deleted modify new merges confl
  if [[ ! -d .git ]]; then
    return
  fi

  branch=$(git branch --show-current 2>/dev/null) || return

  # Fetch ahead/behind counts
  if git rev-parse --abbrev-ref "@{u}" &>/dev/null; then
    behind=$(git rev-list --count HEAD..@{u})
    ahead=$(git rev-list --count @{u}..HEAD)
  else
    behind=0 ahead=0
  fi

  # Parse working directory state
  local -a statusLines
  statusLines=(${(@f)$(git status --short)})
  new=0
  untracked=0
  modify=0
  deleted=0
  merges=0
  for line in "${statusLines[@]}"; do
    # Untracked
    if [[ $line == '??'* ]]; then
      ((untracked++))
      continue
    fi
    # Merge/conflict codes (first two chars)
    conflict_code="${line:0:2}"
    case $conflict_code in
      UU|AA|DD|AU|UA|UD|DU)
        ((merges++))
        continue
        ;;
    esac
    # Index and worktree columns
    index_col="${line:0:1}"
    worktree_col="${line:1:1}"
    # Staged new
    [[ $index_col == 'A' ]] && ((new++))
    # Modified
    [[ $index_col == 'M' || $worktree_col == 'M' || $index_col == 'T' || $worktree_col == 'T' || $index_col == 'R' || $worktree_col == 'R' || $index_col == 'C' || $worktree_col == 'C' ]] && ((modify++))
    # Deleted
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
# ====== End gitStatus translation ======

# ====== Capture time for elapsed execution (optional) ======
preexec() {
  ELAPSED_START=$(date +%s.%N)
}

precmd() {
  local exit_status=$?
  setopt localoptions
  if [[ -n $ELAPSED_START ]]; then
    local elapsed
    elapsed=$(printf "%.1f" "$(echo "$(date +%s.%N) - $ELAPSED_START" | bc)")
  else
    elapsed=""
  fi

  # Path block only
  local cwdBlock="%F{green}%~%f"

  # Terminal title update (Current Folder)
  print -Pn "\e]0;Current Folder: %~\a"

  # Exit status indicator
  local statusIndicator=""
  if (( exit_status != 0 )); then
    statusIndicator="%F{red}✗${exit_status}%f "
  fi

  # Git block
  GIT_ENTRY=$(gitStatus)
  local gitBlock=""
  if [[ -n $GIT_ENTRY ]]; then
    gitBlock="%F{yellow}${GIT_ENTRY}%f"
  fi

  export PS1="${statusIndicator}${cwdBlock}${gitBlock} > "
  if [[ -n $elapsed ]]; then
    export RPROMPT="%F{magenta}${elapsed}s%f"
  else
    export RPROMPT=""
  fi
}

# ====== Prompt done ======

# Auto enable this for interactive shells
if [[ $- == *i* ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd precmd
  add-zsh-hook preexec preexec
fi