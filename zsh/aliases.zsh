# Existing shorthand, with prod as the preferred default branch.
alias ga='git add -p && git commit -m '
alias gb='git branch'
alias gc='git checkout'
alias gcd='git checkout dev || git checkout develop || git checkout test'
alias gcm='git checkout prod || git checkout main || git checkout master'
alias gd='git diff'
alias gf='git reset HEAD --hard'
alias gffs='git reset HEAD --soft'
alias gg='git grep --break --heading --line-number'
alias gi='git init'
alias gl="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gm='git merge prod || git merge master || git merge main'
alias gmt='git mergetool'
alias gp='git pull'
alias gr='git rebase -i'
alias gsd='git switch dev || git switch develop || git switch test'
alias gsm='git switch prod || git switch main || git switch master'
alias gsh='git stash'
alias gsp='git stash pop'
alias gt='git status'
alias gx='git shortlog -sn'
alias gz='git push --force-with-lease --force-if-includes'
alias gtc='git town compress'
alias gtd='git town diff-parent'
alias gth='git town hack'
alias gts='git town sync'
alias gtw='git town switch'
alias lg='lazygit'

# Resolve branch and commit when invoked, never during shell startup.
gtp() {
  local branch title
  branch=$(command git branch --show-current) || return
  [[ -n $branch ]] || { print -u2 'gtp: select a branch first'; return 1; }
  title=$(command git log -1 --pretty=%B) || return
  command gh pr create -B prod -H "$branch" -t "$title" -b "$@"
}
gu() {
  local branch
  branch=$(command git symbolic-ref --quiet --short HEAD) || return
  command git pull origin "$branch" && command git push origin "$branch"
}

alias ja='jj rebase'
alias jb='jj bookmark'
alias jc='jj commit'
alias jd='jj describe'
alias je='jj edit'
alias jf='jj fix'
alias jg='jj git'
alias ji='jj git init --colocate'
alias jk='jj abandon'
alias jl="jj log -r 'ancestors(@, 11)'"
alias jm='jj metaedit --update-change-id'
alias js='jj squash'
alias jt='jj status'
alias ju='jj undo'
jn() {
  command jj git fetch --remote origin || return
  if (( $# )); then
    command jj new "$@"
  else
    command jj new 'trunk()'
  fi
}
jr() { command jj abandon '(empty() & description(exact:"") & mutable()) ~ @'; }
jz() {
  if (( $# != 1 )); then
    print -u2 'Usage: jz <bookmark>'
    return 2
  fi
  command jj git push --bookmark "$1" && jn "$1"
}

(( $+commands[eza] )) && alias ls='eza'
alias mkdir='mkdir -pv'
(( $+commands[awsume] )) && alias awsume='source awsume'
(( $+commands[xrandr] )) && alias dis2pr='xrandr --output LVDS1 --auto --output VGA1 --rotate left --auto --right-of LVDS1'

genpasswd() {
  local length=${1:-20}
  [[ $length == <1-> ]] || { print -u2 'Usage: genpasswd [positive length]'; return 2; }
  LC_ALL=C tr -dc '[:graph:]' < /dev/urandom | tr -d "oO0{}$:;!\\\"'*|?Ql1Ii" | head -c "$length" | xargs -0
}
ds() {
  if [[ $OSTYPE == darwin* ]]; then
    date -r "$1"
  else
    date -d "@$1"
  fi
}
return 0
