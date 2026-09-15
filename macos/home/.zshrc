

# =============================================================================
# ZSH CONFIGURATION
# =============================================================================

# --- History Configuration ---
HISTSIZE=999999
SAVEHIST=999999
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# --- Key Bindings ---

# bindkey "\e[A" history-search-backward
# bindkey "\e[B" history-search-forward

# Home Key
bindkey "\033[1~" beginning-of-line
# End Key
bindkey "\033[4~" end-of-line


autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search



# --- Completion Settings ---
setopt AUTO_LIST
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
fpath=(/usr/local/share/zsh-completions ~/.zsh $fpath)
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit


# --- Environment Variables ---
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/make/libexec/gnubin:$HOME/bin:/opt/homebrew/opt/openssl@3/bin:$HOME/.local/bin:$HOME/Library/Python/3.9/bin:$PATH"
export AWS_CONFIG_FILE=~/.aws
export AWS_CA_BUNDLE=$HOMEBREW_PREFIX/etc/ca-certificates/cert.pem
export HISTTIMEFORMAT='%F %T '
export VISUAL=vim
export EDITOR="$VISUAL"
export TERM=xterm-256color
export OLLAMA_KEEP_ALIVE="-1"

# HF_TOKEN omitted from export; supply through your private environment.

# =============================================================================
# GIT PROMPT FUNCTIONS
# =============================================================================

function __git_colour {
  local c="$(git status 2>/dev/null | grep 'nothing.*to commit')"
  if [ -z "$c" ]; then
    echo "%F{196}"  # red
  else
    echo "%F{46}"   # green
  fi
}

function __gitb {
  local b="$(git symbolic-ref HEAD 2>/dev/null)"
  if [ -n "$b" ]; then
    echo "${b##refs/heads/}"
  fi
}

function __git_ps1 {
  local branch="$(__gitb)"
  [ -n "$branch" ] && echo "($branch)"
}

# =============================================================================
# PROMPT CONFIGURATION
# =============================================================================

setopt PROMPT_SUBST

# Define prompt with proper zsh color codes
PS1='%F{146}%n@%m %F{46}%D{%Y-%m-%d} %D{%H:%M:%S}%F{33}${SSH_TTY} %F{88}+${SHLVL}\
 %F{226}%~$(__git_colour)$(__git_ps1) %F{178}($SHLVL:%!)%F{255}$ %f'

# =============================================================================
# COMPLETIONS
# =============================================================================

# Git-town completions
if command -v git-town &> /dev/null; then
  source <(git-town completions zsh)
fi

# Terraform completions
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# AWS CLI completions
complete -C aws_completer aws

# AWSume completions (zsh)
_awsume() {
  local -a completions
  completions=(${(f)"$(awsume-autocomplete)"})
  _describe 'awsume' completions
}
compdef _awsume awsume

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Generate random password of specified length (default: 20)
genpasswd() {
  local l=$1
  [ "$l" == "" ] && l=20
  tr -dc {[:graph:]} < /dev/urandom | tr -d "oO0{}$:;!\\\"'*|?Ql1Ii" | head -c ${l} | xargs -0
}

# Convert Unix timestamp to human-readable date
# Usage: ds <timestamp>
function ds() { 
  date -r "$1"
}

# =============================================================================
# SSH AGENT MANAGEMENT
# =============================================================================

SSH_AGENT_CACHE=/tmp/ssh_agent_eval_`whoami`
if [ -s "${SSH_AGENT_CACHE}" ]; then
  echo "Reusing existing ssh-agent"
  eval `cat "${SSH_AGENT_CACHE}"`
  # Check that agent still exists
  kill -0 "${SSH_AGENT_PID}" 2>/dev/null
  if [ $? -eq 1 ]; then
    echo "ssh-agent pid ${SSH_AGENT_PID} no longer running"
    rm -f "${SSH_AGENT_CACHE}"
  fi
fi

# =============================================================================
# GIT ALIASES
# =============================================================================
# Based on: http://jasonm23.github.io/oh-my-git-aliases.html

alias ga="git add -p && git commit -m "
alias gb="git branch"
alias gc="git checkout"
alias gcd="git checkout dev || git checkout develop || git checkout test"
alias gcm="git checkout main || git checkout master"
alias gd="git diff "
alias gf="git reset HEAD --hard"        # git f$@k
alias gffs="git reset HEAD --soft"      # git 4 f$@kssake
alias gg="git grep --break --heading --line-number "
alias gi="git init"
alias gl="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gm="git merge master || git merge main"
alias gmt="git mergetool"
alias gp="git pull"
alias gr="git -i rebase"
alias gsd="git switch dev || git switch develop || git switch test"
alias gsm="git switch main || git switch master"
alias gsh="git stash"                   # git hide my work
alias gsp="git stash pop"
alias gt="git status"
alias gtp="gh pr create -B main -H \"$(git branch --show-current)\" -t \"$(git log -1 --pretty=%B)\" -b "
alias gu="git pull origin $(__gitb) && git push origin $(__gitb)"  # git catch up
alias gx="git shortlog -sn"
alias gz="git push --force-with-lease --force-if-includes"         # git zzzz

# Git-town aliases (https://www.git-town.com/)
alias gtc="git town compress"
alias gtd="git town diff-parent"
alias gth="git town hack"
alias gts="git town sync"
alias gtw="git town switch"

# LazyGit (https://github.com/jesseduffield/lazygit)
alias lg="lazygit"

# container apple containers # brew install container
# doppler doppler.com # .env saving
# fd github.com/sharkdp/fd
# fzf github.com/junegunn/fzf
# hx helix
# n8n n8n.io
# rg ripgrep # ag replace?
# tmux https://www.youtube.com/watch?v=DzNmUNvnB04
#   https://github.com/dreamsofcode-io/tmux
# z zoxide

# Jujustu stuff, don't forget jjui
alias ja="jj rebase"
alias jb="jj bookmark"
alias jc="jj commit"
alias jd="jj describe"
alias je="jj edit"
alias jf="jj fix"
alias jg="jj git"
alias ji="jj git init"
# jj jujutsu
alias jk="jj abandon"
alias jl="jj log -r 'ancestors(@, 11)'"
alias jm="jj metaedit --update-change-id"
jn () {
  if (( $# )); then
    jj git fetch --remote origin
    jj new "$@"
  else
    jj git fetch --remote origin
    jj new main@origin
  fi
}
# jq JSON query processor
jr () {
  jj abandon '(empty() & description(exact:"") & mutable()) ~ @'
}
alias js="jj squash"
alias jt="jj status"
alias ju="jj undo"
function jz {
  local b
  b=$(jj bookmark list | head -n 1 | cut -d':' -f1)
  jj git push -b "$b"
  jn "$b"
}

# jjui jujutsu ui

  # abandon           Abandon a revision
  # absorb            Move changes from a revision into the stack of mutable revisions
  # bisect            Find a bad revision by bisection
  # bookmark          Manage bookmarks [default alias: b]
  # commit            Update the description and create a new change on top [default alias: ci]
  # config            Manage config options
  # describe          Update the change description or other metadata [default alias: desc]
  # diff              Compare file contents between two revisions
  # diffedit          Touch up the content changes in a revision with a diff editor
  # duplicate         Create new changes with the same content as existing ones
  # edit              Sets the specified revision as the working-copy revision
  # evolog            Show how a change has evolved over time [aliases: evolution-log]
  # file              File operations
  # fix               Update files with formatting fixes or other changes
  # gerrit            Interact with Gerrit Code Review
  # git               Commands for working with Git remotes and the underlying Git repo
  # help              Print this message or the help of the given subcommand(s)
  # interdiff         Show differences between the diffs of two revisions
  # log               Show revision history
  # metaedit          Modify the metadata of a revision without changing its content
  # new               Create a new, empty change and (by default) edit it in the working copy
  # next              Move the working-copy commit to the child revision
  # operation         Commands for working with the operation log [aliases: op]
  # parallelize       Parallelize revisions by making them siblings
  # prev              Change the working copy revision relative to the parent revision
  # rebase            Move revisions to different parent(s)
  # redo              Redo the most recently undone operation
  # resolve           Resolve conflicted files with an external merge tool
  # restore           Restore paths from another revision
  # revert            Apply the reverse of the given revision(s)
  # root              Show the current workspace root directory (shortcut for `jj workspace root`)
  # show              Show commit description and changes in a revision
  # sign              Cryptographically sign a revision
  # simplify-parents  Simplify parent edges for the specified revision(s)
  # sparse            Manage which paths from the working-copy commit are present in the working copy
  # split             Split a revision in two
  # squash            Move changes from a revision into another revision
  # status            Show high-level repo status [default alias: st]
  # tag               Manage tags
  # undo              Undo the last operation
  # unsign            Drop a cryptographic signature
  # util              Infrequently used commands such as for generating shell completions
  # version           Display version information
  # workspace         Commands for working with workspaces



# =============================================================================
# GENERAL ALIASES
# =============================================================================

alias ls="eza"                          # Use eza (modern ls replacement)
alias mkdir='mkdir -pv'
alias awsume=". awsume"
alias dis2pr="xrandr --output LVDS1 --auto --output VGA1 --rotate left --auto --right-of LVDS1"

# =============================================================================
# END OF CONFIGURATION
# =============================================================================

#AWSume alias to source the AWSume script
alias awsume="source awsume"

autoload -Uz compinit
compinit

FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"


# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/mt/.lmstudio/bin"
# End of LM Studio CLI section


# bun completions
[ -s "/Users/mt/.bun/_bun" ] && source "/Users/mt/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


# pnpm
export PNPM_HOME="/Users/mt/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# android builds

export ANDROID_SDK_ROOT=/Volumes/LaCie/Android/sdk
export ANDROID_HOME=/Volumes/LaCie/Android/sdk
export ANDROID_AVD_HOME=/Volumes/LaCie/Android/avd
export GRADLE_USER_HOME=/Volumes/LaCie/Android/gradle

export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"


export JAVA_HOME=$(/usr/libexec/java_home -v 26)
export PATH="$JAVA_HOME/bin:$PATH"
