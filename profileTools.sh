#!/bin/bash

# Download and update this script from GitHub
syncProfileTools() {
    local profile_tools_path="$HOME/.profileTools.sh"
    curl -fsSL "https://raw.githubusercontent.com/barnuri/mac-utils/master/profileTools.sh" -o "$profile_tools_path"
    if ! grep -q 'source $HOME/.profileTools.sh' "$HOME/.zshrc"; then
        echo '### load profileTools.sh' >> "$HOME/.zshrc"
        echo 'source $HOME/.profileTools.sh' >> "$HOME/.zshrc"
    fi
    source "$profile_tools_path"
    echo "Profile tools updated and sourced."
}

alias grep='rg'
alias reloadProfile='source $HOME/.zshrc'
alias ls='ls -alF'
alias k='kubectl'

# Python venv helpers
p3venv() { python3 -m venv venv; }
p2venv() { python2 -m virtualenv venv; }
venvActivate() { source ./venv/bin/activate; }

# pip install helpers
pipi() {
    python3 -m pip install --upgrade pip
    pip install --upgrade -r REQUIREMENTS
}
pipp() {
    python3 -m pip install --upgrade pip
    pip install .
}

# Git helpers
gitGetDefaultBranch() {
    git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo master
}
gitRemoveMergedBranches() {
    git branch --merged | grep -v '\*' | grep -v master | xargs -n 1 git branch -d
}
getAllBranches() {
    git branch -a | sed 's/.* //;s/remotes\///' | sort -u | grep -v HEAD
}
gitCleanLocalBranches() {
    git fetch --all --prune
    git branch | grep -v '\*' | xargs -n 1 git branch -D
}
gitCleanIgnoreFiles() {
    git clean -dfx -f
}
gitMergeTo() {
    local targetBranchName="${1:-integration}"
    local currentBranch=$(git branch --show-current)
    git checkout "$targetBranchName"
    git pull --no-edit
    git merge -X ignore-all-space --no-ff "$currentBranch"
    git push
    git checkout "$currentBranch"
}
alias gitmt=gitMergeTo
gitc() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git checkout "$branchName"
    git pull --no-edit
}
gitnb() { git checkout -b "$1"; }
gitnbm() {
    local branchName="$1"
    local defaultBranch=$(gitGetDefaultBranch)
    git fetch origin "$defaultBranch"
    git checkout "origin/$defaultBranch"
    gitnb "$branchName"
}
gitm() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git fetch origin "$branchName"
    git pull --no-edit
    git merge -X ignore-all-space --no-ff "origin/$branchName"
}
gitMoveToHttps() {
    local url=$(git remote get-url origin)
    [[ "$url" == http* ]] && return
    local moveToHttp=${url/git@/https://}
    moveToHttp=${moveToHttp/:/\/}
    git remote set-url origin "$moveToHttp"
}
gitMoveToSSH() {
    local url=$(git remote get-url origin)
    [[ "$url" == git@* ]] && return
    local moveToSsh=${url/https:\/\//git@}
    moveToSsh=${moveToSsh/http:\/\//git@}
    moveToSsh=${moveToSsh//\//:}
    git remote set-url origin "$moveToSsh"
}
gitDiff() {
    local branchName="${1:-$(gitGetDefaultBranch)}"
    git fetch origin "$branchName"
    git diff "origin/$branchName...$(git branch --show-current)" --name-status
}
gitCheckoutFile() {
    local branchName="$1"; shift
    git fetch origin "$branchName"
    git checkout "origin/$branchName" -- "$@"
}
gitCurrentBranchName() {
    git rev-parse --abbrev-ref HEAD
}
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
alias gitp=gitCommitAndPush

gitOriginUrl() {
    local repoUrl=$(git config --get remote.origin.url)
    repoUrl=${repoUrl#git@}
    repoUrl=${repoUrl/:/\/}
    repoUrl=${repoUrl%.git}
    [[ "$repoUrl" != http* ]] && repoUrl="https://$repoUrl"
    echo "$repoUrl"
}

gitEmptyCommit() {
    local msg="${1:-empty commit - trigger status checks}"
    git commit --allow-empty -m "$msg"
    git pull --no-edit
    git push
}

gitSpeedUp() {
    git fsck
    git repack -ad
    git gc --aggressive --prune=now --force
    git status
}

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

