#!/bin/bash

# Download and update this script from GitHub
syncProfileToolsFunc() {
    local profile_tools_path="$HOME/profileTools.sh"
    curl -fsSL "https://raw.githubusercontent.com/barnuri/dev-tools/refs/heads/master/mac-utils/profileTools.sh" -o "$profile_tools_path"
    current_source_content=$(cat "$HOME/.zshrc")
    if [[ $current_source_content != *"source $profile_tools_path"* ]]; then
        echo "source $profile_tools_path" >> "$HOME/.zshrc"
        echo "Added profile tools sourcing to .zshrc."
    fi
    source "$profile_tools_path"
    echo "Profile tools updated and sourced."
}
alias syncProfileTools=syncProfileToolsFunc

alias grep='rg'
alias reloadProfile='source $HOME/.zshrc'
alias ls='lsd -alF'
alias l="ls -l"
alias k='kubecolor'

venvActivateFunc() {
    local venv_dir="${1:-.}"
    source "$venv_dir/.venv/bin/activate"
}
alias venvActivate=venvActivateFunc

# pip install helpers
pipiFunc() {
    python3 -m pip install --upgrade pip
    pip install --upgrade -r REQUIREMENTS
}
alias pipi=pipiFunc
pippFunc() {
    python3 -m pip install --upgrade pip
    pip install .
}
alias pipp=pippFunc

# Git helpers
gitGetDefaultBranchFunc() {
    val=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p' || echo "master")
    echo "$val"
}
alias gitGetDefaultBranch=gitGetDefaultBranchFunc
gitRemoveMergedBranchesFunc() {
    git branch --merged | grep -v '\*' | grep -v master | xargs -n 1 git branch -d
}
alias gitRemoveMergedBranches=gitRemoveMergedBranchesFunc
getAllBranchesFunc() {
    git branch -a | sed 's/.* //;s/remotes\///' | sort -u | grep -v HEAD
}
alias getAllBranches=getAllBranchesFunc
gitCleanLocalBranchesFunc() {
    git fetch --all --prune
    git branch | grep -v '\*' | xargs -n 1 git branch -D
}
alias gitCleanLocalBranches=gitCleanLocalBranchesFunc
gitCleanIgnoreFilesFunc() {
    git clean -dfx -f
}
alias gitCleanIgnoreFiles=gitCleanIgnoreFilesFunc
gitMergeToFunc() {
    local targetBranchName="${1:-integration}"
    local currentBranch=$(git branch --show-current)
    git checkout "$targetBranchName"
    git pull --no-edit
    git merge -X ignore-all-space --no-edit --no-ff "$currentBranch"
    git push
    git checkout "$currentBranch"
}
alias gitMergeTo=gitMergeToFunc
alias gitmt=gitMergeToFunc
gitcFunc() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git checkout "$branchName" --ignore-other-worktrees
    git pull --no-edit
}
alias gitc=gitcFunc
gitnbFunc() { git checkout -b "$1" --ignore-other-worktrees; }
alias gitnb=gitnbFunc
gitnbmFunc() {
    local branchName="$1"
    local defaultBranch=$(gitGetDefaultBranch)
    git fetch origin "$defaultBranch"
    git checkout "origin/$defaultBranch" --ignore-other-worktrees
    gitnb "$branchName"
}
alias gitnbm=gitnbmFunc
gitmFunc() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git fetch origin "$branchName"
    git pull --no-edit
    git merge -X ignore-all-space --no-ff "origin/$branchName" --no-edit
}
alias gitm=gitmFunc
gitMoveToHttpsFunc() {
    local url=$(git remote get-url origin)
    [[ "$url" == http* ]] && return
    local moveToHttp=${url/git@/https://}
    moveToHttp=${moveToHttp/:/\/}
    git remote set-url origin "$moveToHttp"
}
alias gitMoveToHttps=gitMoveToHttpsFunc
gitMoveToSSHFunc() {
    local url=$(git remote get-url origin)
    [[ "$url" == git@* ]] && return
    local moveToSsh=${url/https:\/\//git@}
    moveToSsh=${moveToSsh/http:\/\//git@}
    moveToSsh=${moveToSsh//\//:}
    git remote set-url origin "$moveToSsh"
}
alias gitMoveToSSH=gitMoveToSSHFunc
gitDiffFunc() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git fetch origin "$branchName"
    git diff "origin/$branchName...$(git branch --show-current)" --name-status
}
alias gitDiff=gitDiffFunc
gitCheckoutFileFunc() {
    local branchName="$1"; shift
    git fetch origin "$branchName"
    git checkout "origin/$branchName" -- "$@"
}
alias gitCheckoutFile=gitCheckoutFileFunc
gitCurrentBranchNameFunc() {
    git rev-parse --abbrev-ref HEAD
}
alias gitCurrentBranchName=gitCurrentBranchNameFunc
gitCommitAndPushFunc() {
    local currentBranchName=$(gitCurrentBranchName)
    if ! git config branch."$currentBranchName".merge &>/dev/null; then
        git push --set-upstream origin "$currentBranchName"
    fi
    git add .
    local msg="${*:-$currentBranchName}"
    git commit -am "$msg"
    git pull --no-edit
    git push
}
alias gitCommitAndPush=gitCommitAndPushFunc
alias gitp=gitCommitAndPushFunc

gitOriginUrlFunc() {
    local repoUrl=$(git config --get remote.origin.url)
    repoUrl=${repoUrl#git@}
    repoUrl=${repoUrl/:/\/}
    repoUrl=${repoUrl%.git}
    [[ "$repoUrl" != http* ]] && repoUrl="https://$repoUrl"
    echo "$repoUrl"
}
alias gitOriginUrl=gitOriginUrlFunc

gitEmptyCommitFunc() {
    local msg="${1:-empty commit - trigger status checks}"
    git commit --allow-empty -m "$msg"
    git pull --no-edit
    git push
}
alias gitEmptyCommit=gitEmptyCommitFunc

gitSpeedUpFunc() {
    git fsck
    git repack -ad
    git gc --aggressive --prune=now --force
    git status
}
alias gitSpeedUp=gitSpeedUpFunc

alias filesByGlob='find . -name "$1"'
alias hardLink='ln -sf "$1" "$2"'
alias hostFile='echo "/etc/hosts"'
readEnvFileFunc() {
    local path="${1:-.env}"
    while IFS= read -r line; do
        [[ "$line" =~ ^\s*# ]] && continue
        [[ "$line" =~ ^\s*$ ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        export "$key"="${value//\"/}"
    done < "$path"
}
alias readEnvFile=readEnvFileFunc

gitCleanCommitsIntoOneFunc() {
    local defaultBranch=$(gitGetDefaultBranch)
    git fetch origin "$defaultBranch"
    git reset $(git merge-base "origin/$defaultBranch" $(git branch --show-current))
    git add -A
    local msg="${*:-$(gitCurrentBranchName)}"
    git commit -m "$msg"
    git push -f
}
alias gitCleanCommitsIntoOne=gitCleanCommitsIntoOneFunc
alias gitSquash=gitCleanCommitsIntoOneFunc

gitCleanCommitsIntoOneWithoutCommitFunc() {
    local defaultBranch=$(gitGetDefaultBranch)
    git fetch origin "$defaultBranch"
    git reset $(git merge-base "origin/$defaultBranch" $(git branch --show-current))
}
alias gitCleanCommitsIntoOneWithoutCommit=gitCleanCommitsIntoOneWithoutCommitFunc
alias gitSquashNoCommit=gitCleanCommitsIntoOneWithoutCommitFunc

export GIT_ASK_YESNO="false"

alias kbuild="kustomize build --load-restrictor=LoadRestrictionsNone --enable-helm"

alias del="rm -rf"




create-pr() {
  local branch draft=0 auto_merge=0

  for arg in "$@"; do
    case "$arg" in
      --draft)      draft=1 ;;
      --auto-merge) auto_merge=1 ;;
    esac
  done

  branch=$(git branch --show-current 2>/dev/null)
  [[ -z "$branch" ]] && { echo "Not in a git repo." >&2; return 1; }

  local ticket_key
  if [[ "$branch" =~ '^([A-Z]+-[0-9]+)' ]]; then
    ticket_key="${match[1]}"
  else
    ticket_key=""
  fi
  if [[ -z "$ticket_key" ]]; then
    echo "Branch '$branch' does not start with a Jira ticket key (e.g. GENAI-123-my-feature)." >&2
    return 1
  fi

  local base
  base=$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
  [[ -z "$base" ]] && base=master

  local label="stg-from-side-branch"
  if ! gh label list --json name -q '.[].name' 2>/dev/null | grep -qx "$label"; then
    echo "Label '$label' not found in repo; creating it..."
    gh label create "$label" --color BFD4F2 --description "Deploy to staging from a side branch" \
      || { echo "Failed to create label '$label'." >&2; return 1; }
  fi

  local slug summary
  slug=$(echo "$branch" | sed "s/^${ticket_key}//" | sed 's/^[-_]*//' | sed 's/[-_]*$//')
  if [[ -n "$slug" ]]; then
    summary="$slug"
  else
    summary=$(git log "${base}..HEAD" --oneline --no-merges 2>/dev/null | tail -1 | sed 's/^[a-f0-9]* //')
  fi
  local title="${ticket_key}: ${summary}"

  local existing_url
  existing_url=$(gh pr list --head "$branch" --state open --json url -q '.[0].url' 2>/dev/null)
  if [[ -n "$existing_url" ]]; then
    echo "Open PR already exists:"
    echo "$existing_url"
    echo -n "$existing_url" | pbcopy
    echo "(copied to clipboard)"
    return 0
  fi

  echo "Pushing branch..."
  git push --set-upstream origin "$branch" || { echo "Push failed." >&2; return 1; }

  local commits
  commits=$(git log "${base}..HEAD" --oneline --no-merges --reverse 2>/dev/null | sed 's/^[a-f0-9]* /- /')

  local create_flags=(--title "$title" --body "$title" --label "$label")
  (( draft )) && create_flags+=(--draft)

  echo "Creating PR: $title"
  local pr_url
  pr_url=$(gh pr create "${create_flags[@]}")
  echo "$pr_url"
  echo -n "$pr_url" | pbcopy
  echo "(copied to clipboard)"

  if (( auto_merge )); then
    echo "Enabling auto-merge..."
    gh pr merge "$pr_url" --auto --squash
  fi
}



h() {
    emulate -L zsh
    command -v herdr >/dev/null || { echo "herdr-space: herdr CLI not found" >&2; return 1; }
    command -v jq >/dev/null || { echo "herdr-space: jq not found" >&2; return 1; }

    # workspace CLI needs a live server; start one if needed before list/create
    if ! herdr status --json 2>/dev/null | jq -e '.server.running == true' >/dev/null; then
        echo "Starting herdr server..."
        herdr server >/dev/null 2>&1 &!
        local i=0
        while (( i < 50 )); do
            herdr status --json 2>/dev/null | jq -e '.server.running == true' >/dev/null && break
            sleep 0.1
            (( i++ ))
        done
        if ! herdr status --json 2>/dev/null | jq -e '.server.running == true' >/dev/null; then
            echo "herdr-space: failed to start herdr server" >&2
            return 1
        fi
    fi

    local name="${1:-$(basename "$PWD")}"
    local list_json
    list_json=$(herdr workspace list 2>&1) || { echo "herdr-space: $list_json" >&2; return 1; }

    local existing_id
    existing_id=$(echo "$list_json" | jq -r --arg name "$name" \
        '.result.workspaces[] | select(.label == $name or (.label | endswith(" " + $name))) | .workspace_id' \
        | head -n1)

    if [[ -n "$existing_id" ]]; then
        herdr workspace focus "$existing_id" >/dev/null
        echo "Focused herdr space '$name' ($existing_id)"
        herdr
        return 0
    fi

    local created_json new_id
    created_json=$(herdr workspace create --cwd "$PWD" --label "$name" --focus 2>&1) \
        || { echo "herdr-space: $created_json" >&2; return 1; }
    new_id=$(echo "$created_json" | jq -r '.result.workspace.workspace_id // empty')
    if [[ -z "$new_id" ]]; then
        echo "herdr-space: failed to create workspace for '$name'" >&2
        echo "$created_json" >&2
        return 1
    fi
    echo "Created + focused herdr space '$name' ($new_id)"
    herdr
}

export HOMEBREW_NO_ENV_HINTS=1

alias code="code-insiders"
alias k="kubecolor"
alias kbuild="kustomize build --load-restrictor=LoadRestrictionsNone --enable-helm"
export EDITOR="code-insiders -w"
export KUBE_EDITOR="code-insiders --wait"


getJobsToDelete() {
    jobs=$(k get jobs -o json | jq '.items[] | select(.status.startTime and ((now - (.status.startTime | fromdateiso8601)) > 1800)) | {jobName: .metadata.name, lastConditionType: (.status.conditions[-1].type)}')
    jobsToDelete=$(echo "$jobs" | jq -r 'select(.lastConditionType == "Complete" or .lastConditionType == "Failed") | .jobName')
    export jobsToDelete="$jobsToDelete"
    export jobs="$jobs"
    echo "Jobs to delete: $jobsToDelete"
}

deleteJobs() {
    if [ -z "$jobsToDelete" ]; then
        echo "No jobs to delete."
        return 0
    fi
    echo "$jobsToDelete" | tr ' ' '\n' | awk NF | sort -u | xargs kubecolor delete job --ignore-not-found
}


retryPRCommitChecks() {
    set -euo pipefail

    PR_REF="${1:-}"

    echo "Fetching PR status checks..."

    if [ -n "$PR_REF" ]; then
        json=$(gh pr view "$PR_REF" --json statusCheckRollup --jq '.statusCheckRollup')
    else
        json=$(gh pr view --json statusCheckRollup --jq '.statusCheckRollup')
    fi

    # Extract unique run IDs from failed CheckRuns
    run_ids=$(echo "$json" | jq -r '
        [ .[] | select(.__typename == "CheckRun" and .conclusion == "FAILURE") | .detailsUrl ]
        | map(capture("/actions/runs/(?<id>[0-9]+)") | .id)
        | unique
        | .[]
    ')

    if [ -z "$run_ids" ]; then
        echo "No failed workflow runs found."
        exit 0
    fi

    count=$(echo "$run_ids" | wc -l | tr -d ' ')
    echo "Found $count failed workflow run(s). Retrying..."

    while IFS= read -r run_id; do
        echo "  Rerunning failed jobs for run $run_id..."
        gh run rerun "$run_id" --failed || echo "  Warning: failed to rerun $run_id"
    done <<< "$run_ids"

    echo "Done."
}

retryPRCommitChecksEveryXMin() {
    local interval="${1:-1}"
    while true; do
        echo "$(date): Running retryPRCommitChecks..."
        retryPRCommitChecks "$2"
        echo "$(date): Completed. Next run in $interval minute(s)."
        echo "---"
        sleep $((interval * 60))
    done
}

killByPort() {
    port="${1:-9090}"
    lsof -t -i tcp:$port | xargs kill
}