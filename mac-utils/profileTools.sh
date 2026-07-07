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
