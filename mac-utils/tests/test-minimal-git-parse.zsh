#!/usr/bin/env zsh
# Unit tests for minimal-git.zsh-theme's porcelain-v2 parsing.
#
# The parser is fed synthetic `git status --porcelain=v2 --branch` output, so these tests
# need no git repository, no network and no fixture setup. Run: zsh tests/test-minimal-git-parse.zsh

emulate -L zsh
# Deliberately no ERR_EXIT: in zsh `(( x++ ))` evaluates to the pre-increment value, so the
# first counter bump returns 0 and would abort the run under ERR_EXIT.
setopt PIPE_FAIL

typeset -g THEME=${0:A:h}/../minimal-git.zsh-theme
source $THEME

typeset -gi PASSED=0 FAILED=0

# Drive _git_status against canned output by overriding the one function that talks to git.
# _git_collect_status is the seam: it fills _git_lines and returns 0 on success.
_stub_collect() {
  # An empty FIXTURE must yield a genuinely empty array. Plain "${(@f)FIXTURE}" would give a
  # one-element array holding the empty string, which is the "partial read" case, not the
  # "git produced nothing" case the non-git test is checking.
  if [[ -n $FIXTURE ]]; then
    _git_lines=("${(@f)FIXTURE}")
  else
    _git_lines=()
  fi
  [[ -n $FIXTURE_FAILS ]] && return 1
  return 0
}

assert_render() {
  local name=$1 expected=$2
  functions[_git_collect_status]=$functions[_stub_collect]
  _git_status
  # Strip zsh colour escapes so assertions read as plain prompt text
  local actual=${${_GIT_STATUS_BLOCK//\%F\{[a-z]##\}/}//\%f/}
  if [[ $actual == $expected ]]; then
    print -r -- "  PASS  $name"
    (( PASSED += 1 ))
  else
    print -r -- "  FAIL  $name"
    print -r -- "        expected: [$expected]"
    print -r -- "        actual:   [$actual]"
    (( FAILED += 1 ))
  fi
}

run() {
  local name=$1 expected=$2
  FIXTURE=$3
  FIXTURE_FAILS=$4
  assert_render $name $expected
}

print -r -- "minimal-git porcelain-v2 parsing"

run "clean tracking branch" " (master =)" \
'# branch.oid abc123
# branch.head master
# branch.upstream origin/master
# branch.ab +0 -0'

run "ahead only" " (master ↑3)" \
'# branch.head master
# branch.ab +3 -0'

run "behind only" " (master ↓2)" \
'# branch.head master
# branch.ab +0 -2'

run "ahead and behind" " (master ↓4 ↑1)" \
'# branch.head master
# branch.ab +1 -4'

run "no upstream is clean, not behind" " (topic =)" \
'# branch.oid abc123
# branch.head topic'

run "detached HEAD" " (no branch =)" \
'# branch.oid abc123
# branch.head (detached)'

run "untracked files" " (master ?2)" \
'# branch.head master
? one.txt
? two.txt'

run "staged add counts as new" " (master +1)" \
'# branch.head master
1 A. N... 100644 100644 100644 0000000 abc123 new.txt'

run "modified in worktree" " (master ±1)" \
'# branch.head master
1 .M N... 100644 100644 100644 abc123 abc123 a.txt'

run "modified in index" " (master ±1)" \
'# branch.head master
1 M. N... 100644 100644 100644 abc123 def456 a.txt'

run "deleted" " (master -1)" \
'# branch.head master
1 .D N... 100644 100644 000000 abc123 abc123 gone.txt'

run "rename counts as modify" " (master ±1)" \
'# branch.head master
2 R. N... 100644 100644 100644 abc123 abc123 R100 new.txt	old.txt'

run "unmerged entry counts as merge conflict" " (master !1)" \
'# branch.head master
u UU N... 100644 100644 100644 100644 abc1 abc2 abc3 both.txt'

run "ignored entries are skipped" " (master =)" \
'# branch.head master
! build/'

run "all counters together" " (master ↓1 ↑2 +1 ?1 ±1 -1 !1)" \
'# branch.head master
# branch.ab +2 -1
1 A. N... 100644 100644 100644 0000000 abc123 added.txt
1 .M N... 100644 100644 100644 abc123 abc123 mod.txt
1 .D N... 100644 100644 000000 abc123 abc123 del.txt
? untracked.txt
u UU N... 100644 100644 100644 100644 a b c conflict.txt'

# A file both staged-modified and worktree-modified is one file, counted once
run "modify counted once per file" " (master ±1)" \
'# branch.head master
1 MM N... 100644 100644 100644 abc123 def456 a.txt'

print -r -- ""
print -r -- "degraded paths"

# Timeout: partial output arrived but no branch.head -> show the unknown marker
run "timeout shows marker" " (…)" \
'# branch.oid abc123' fails

# Not a git repo: no output at all -> render nothing, so the prompt has no git block
run "non-git dir renders nothing" "" "" fails

print -r -- ""
print -r -- "passed: $PASSED  failed: $FAILED"
(( FAILED == 0 ))
