# minimal-git.zsh-theme
# A minimal, fast, and informative Zsh theme with git status

# Enable colors and prompt substitution
autoload -Uz colors
colors
setopt PROMPT_SUBST
setopt EXTENDED_GLOB

# EPOCHREALTIME for the command timer — avoids forking date(1) twice and bc(1) once per prompt
zmodload zsh/datetime

# Seconds to wait for git before giving up and rendering a degraded block.
# This is a hang guard, not a latency target: a healthy repo answers in ~0.04s and never
# reaches it. Lower it if a stalled git makes the prompt feel sticky.
: ${MINIMAL_GIT_TIMEOUT:=3.0}

# Rendered when git did not answer within MINIMAL_GIT_TIMEOUT. Deliberately distinct from
# the clean marker — showing "=" here would claim a clean tree we never actually saw.
typeset -g _MINIMAL_GIT_UNKNOWN=' %F{yellow}(%F{red}…%F{yellow})%f'

# Collect `git status --porcelain=v2 --branch` output into _git_lines, bounded by a timeout.
#
# macOS ships no timeout(1) (it is GNU coreutils), so the bound is built from zsh builtins:
# the command runs as a coprocess and `read -p -t` gives up on its own. Nothing extra forks.
#
# Returns 0 only when the output carries a `# branch.head` header. `read`'s own exit status
# cannot distinguish EOF from a tripped timeout in this loop form, so success is judged by
# content instead — which also covers "not a git repository" and any git error for free.
_git_collect_status() {
  _git_lines=()
  local line saw_header=0

  coproc git status --porcelain=v2 --branch 2>/dev/null
  local coproc_pid=$!

  while IFS= read -r -p -t $MINIMAL_GIT_TIMEOUT line; do
    _git_lines+=("$line")
    [[ $line == '# branch.head '* ]] && saw_header=1
  done

  if (( ! saw_header )); then
    # Kill the whole process group first: a stalled git may itself be blocked on a child
    # (credential helper, filesystem probe), and TERMing only the leader orphans that child.
    # Falls back to the single pid when the coprocess is not its own group leader.
    kill -TERM -- -$coproc_pid 2>/dev/null || kill -TERM $coproc_pid 2>/dev/null
    return 1
  fi
  return 0
}

# Git status function
_git_status() {
  _GIT_STATUS_BLOCK=''

  local -a _git_lines
  if ! _git_collect_status; then
    # A repo that answered but has no branch.head is not a repo at all (or git failed);
    # only a partial read means the timeout tripped and the user should see the marker.
    (( ${#_git_lines} )) && _GIT_STATUS_BLOCK=$_MINIMAL_GIT_UNKNOWN
    return
  fi

  local branch='' line index_col worktree_col
  integer ahead=0 behind=0 new=0 untracked=0 modify=0 deleted=0 merges=0

  for line in "${_git_lines[@]}"; do
    case $line in
      '# branch.head '*)
        branch=${line#'# branch.head '}
        # git writes the literal "(detached)" when HEAD is not on a branch
        [[ $branch == '(detached)' ]] && branch=''
        continue
        ;;
      # "# branch.ab +3 -1" — absent entirely when the branch has no upstream
      '# branch.ab '*)
        local ab=${line#'# branch.ab '}
        ahead=${${ab%% *}#+}
        behind=${${ab##* }#-}
        continue
        ;;
      '#'*) continue ;;
      '? '*) (( untracked++ )); continue ;;
      # "u " is an unmerged entry: porcelain v2 reports conflicts on their own line type,
      # so the v1 two-letter codes (UU/AA/DD/...) never need to be matched here.
      'u '*) (( merges++ )); continue ;;
      '! '*) continue ;;
    esac

    # Ordinary ("1 XY ...") and renamed/copied ("2 XY ...") entries share an XY field
    # in the second column. Anything else is not a status entry.
    [[ $line == ('1'|'2')' '* ]] || continue
    index_col=${line[3]}
    worktree_col=${line[4]}

    [[ $index_col == 'A' ]] && (( new++ ))
    [[ $index_col == [MTRC] || $worktree_col == [MTRC] ]] && (( modify++ ))
    [[ $index_col == 'D' || $worktree_col == 'D' ]] && (( deleted++ ))
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
  _GIT_STATUS_BLOCK="${statusDisplay}%f"
}

# Preexec: capture start time
_minimal_git_preexec() {
  ELAPSED_START=$EPOCHREALTIME
}
preexec_functions+=(_minimal_git_preexec)

# Precmd: set prompt
_minimal_git_precmd() {
  local exit_status=$?
  setopt localoptions
  local elapsed=""
  if [[ -n $ELAPSED_START ]]; then
    # printf -v assigns in-shell; $(printf ...) would fork a subshell and undo the point
    printf -v elapsed "%.1f" $(( EPOCHREALTIME - ELAPSED_START ))
  fi
  local cwdBlock="%F{green}%~%f"
  print -Pn "\e]0;Current Folder: %~\a"
  local gitBlock=""
  _git_status
  if [[ -n $_GIT_STATUS_BLOCK ]]; then
    gitBlock="%F{yellow}${_GIT_STATUS_BLOCK}%f"
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
precmd_functions+=(_minimal_git_precmd)
