#!/bin/bash

# Download and update this script from GitHub
syncProfileTools() {
    local profile_tools_path="$HOME/.profileTools.sh"
    curl -fsSL "https://raw.githubusercontent.com/barnuri/dev-tools/refs/heads/master/mac-utils/.profileTools.sh" -o "$profile_tools_path"
    current_source_content=$(cat "$HOME/.zshrc")
    if [[ $current_source_content != *"source $profile_tools_path"* ]]; then
        echo "source $profile_tools_path" >> "$HOME/.zshrc"
        echo "Added profile tools sourcing to .zshrc."
    fi
    source "$profile_tools_path"
    echo "Profile tools updated and sourced."
}
alias syncProfileTools=syncProfileTools

alias grep='rg'
alias reloadProfile='source $HOME/.zshrc'
alias ls='lsd -alF'
alias l="ls -l"
alias k='kubecolor'

venvActivate() {
    local venv_dir="${1:-.}"
    source "$venv_dir/.venv/bin/activate"
}
alias venvActivate=venvActivate

# pip install helpers
pipi() {
    python3 -m pip install --upgrade pip
    pip install --upgrade -r REQUIREMENTS
}
alias pipi=pipi
pipp() {
    python3 -m pip install --upgrade pip
    pip install .
}
alias pipp=pipp

# Git helpers
gitGetDefaultBranch() {
    git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo master
}
alias gitGetDefaultBranch=gitGetDefaultBranch
gitRemoveMergedBranches() {
    git branch --merged | grep -v '\*' | grep -v master | xargs -n 1 git branch -d
}
alias gitRemoveMergedBranches=gitRemoveMergedBranches
getAllBranches() {
    git branch -a | sed 's/.* //;s/remotes\///' | sort -u | grep -v HEAD
}
alias getAllBranches=getAllBranches
gitCleanLocalBranches() {
    git fetch --all --prune
    git branch | grep -v '\*' | xargs -n 1 git branch -D
}
alias gitCleanLocalBranches=gitCleanLocalBranches
gitCleanIgnoreFiles() {
    git clean -dfx -f
}
alias gitCleanIgnoreFiles=gitCleanIgnoreFiles
gitMergeTo() {
    local targetBranchName="${1:-integration}"
    local currentBranch=$(git branch --show-current)
    git checkout "$targetBranchName"
    git pull --no-edit
    git merge -X ignore-all-space --no-ff "$currentBranch"
    git push
    git checkout "$currentBranch"
}
alias gitMergeTo=gitMergeTo
alias gitmt=gitMergeTo
gitc() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git checkout "$branchName"
    git pull --no-edit
}
alias gitc=gitc
gitnb() { git checkout -b "$1"; }
alias gitnb=gitnb
gitnbm() {
    local branchName="$1"
    local defaultBranch=$(gitGetDefaultBranch)
    git fetch origin "$defaultBranch"
    git checkout "origin/$defaultBranch"
    gitnb "$branchName"
}
alias gitnbm=gitnbm
gitm() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git fetch origin "$branchName"
    git pull --no-edit
    git merge -X ignore-all-space --no-ff "origin/$branchName"
}
alias gitm=gitm
gitMoveToHttps() {
    local url=$(git remote get-url origin)
    [[ "$url" == http* ]] && return
    local moveToHttp=${url/git@/https://}
    moveToHttp=${moveToHttp/:/\/}
    git remote set-url origin "$moveToHttp"
}
alias gitMoveToHttps=gitMoveToHttps
gitMoveToSSH() {
    local url=$(git remote get-url origin)
    [[ "$url" == git@* ]] && return
    local moveToSsh=${url/https:\/\//git@}
    moveToSsh=${moveToSsh/http:\/\//git@}
    moveToSsh=${moveToSsh//\//:}
    git remote set-url origin "$moveToSsh"
}
alias gitMoveToSSH=gitMoveToSSH
gitDiff() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git fetch origin "$branchName"
    git diff "origin/$branchName...$(git branch --show-current)" --name-status
}
alias gitDiff=gitDiff
gitCheckoutFile() {
    local branchName="$1"; shift
    git fetch origin "$branchName"
    git checkout "origin/$branchName" -- "$@"
}
alias gitCheckoutFile=gitCheckoutFile
gitCurrentBranchName() {
    git rev-parse --abbrev-ref HEAD
}
alias gitCurrentBranchName=gitCurrentBranchName
gitCommitAndPush() {
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
alias gitCommitAndPush=gitCommitAndPush
alias gitp=gitCommitAndPush

gitOriginUrl() {
    local repoUrl=$(git config --get remote.origin.url)
    repoUrl=${repoUrl#git@}
    repoUrl=${repoUrl/:/\/}
    repoUrl=${repoUrl%.git}
    [[ "$repoUrl" != http* ]] && repoUrl="https://$repoUrl"
    echo "$repoUrl"
}
alias gitOriginUrl=gitOriginUrl

gitEmptyCommit() {
    local msg="${1:-empty commit - trigger status checks}"
    git commit --allow-empty -m "$msg"
    git pull --no-edit
    git push
}
alias gitEmptyCommit=gitEmptyCommit

gitSpeedUp() {
    git fsck
    git repack -ad
    git gc --aggressive --prune=now --force
    git status
}
alias gitSpeedUp=gitSpeedUp

alias filesByGlob='find . -name "$1"'
alias hardLink='ln -sf "$1" "$2"'
alias hostFile='echo "/etc/hosts"'
readEnvFile() {
    local path="${1:-.env}"
    while IFS= read -r line; do
        [[ "$line" =~ ^\s*# ]] && continue
        [[ "$line" =~ ^\s*$ ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        export "$key"="${value//\"/}"
    done < "$path"
}
alias readEnvFile=readEnvFile

gitCleanCommitsIntoOne() {
    local defaultBranch=$(gitGetDefaultBranch)
    git fetch origin "$defaultBranch"
    git reset $(git merge-base "origin/$defaultBranch" $(git branch --show-current))
    git add -A
    local msg="${*:-$(gitCurrentBranchName)}"
    git commit -m "$msg"
    git push -f
}
alias gitCleanCommitsIntoOne=gitCleanCommitsIntoOne
alias gitSquash=gitCleanCommitsIntoOne

gitCleanCommitsIntoOneWithoutCommit() {
    local defaultBranch=$(gitGetDefaultBranch)
    git fetch origin "$defaultBranch"
    git reset $(git merge-base "origin/$defaultBranch" $(git branch --show-current))
}
alias gitCleanCommitsIntoOneWithoutCommit=gitCleanCommitsIntoOneWithoutCommit
alias gitSquashNoCommit=gitCleanCommitsIntoOneWithoutCommit

export GIT_ASK_YESNO="false"
