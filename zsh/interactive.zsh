source "${${(%):-%N}:A:h}/environment.zsh"
[[ -o interactive ]] || return 0

HISTSIZE=999999
SAVEHIST=999999
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
setopt HIST_IGNORE_DUPS HIST_FIND_NO_DUPS SHARE_HISTORY AUTO_LIST PROMPT_SUBST
bindkey '\033[1~' beginning-of-line
bindkey '\033[4~' end-of-line
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
typeset -U fpath
[[ -n ${HOMEBREW_PREFIX-} ]] && fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" "$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
[[ -d $HOME/.zsh ]] && fpath=("$HOME/.zsh" $fpath)
autoload -Uz compinit bashcompinit
compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"
bashcompinit

(( $+commands[git-town] )) && source <(command git-town completions zsh)
(( $+commands[terraform] )) && complete -o nospace -C "${commands[terraform]}" terraform
(( $+commands[aws_completer] )) && complete -C "${commands[aws_completer]}" aws
if (( $+commands[awsume-autocomplete] )); then
  _awsume() {
    local -a completions
    completions=(${(f)"$(awsume-autocomplete)"})
    _describe 'awsume' completions
  }
  compdef _awsume awsume
fi
[[ -r $BUN_INSTALL/_bun ]] && source "$BUN_INSTALL/_bun"
[[ -n ${HOMEBREW_PREFIX-} && -r $HOMEBREW_PREFIX/opt/nvm/nvm.sh ]] &&
  source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"

source "$BA_ROOT/zsh/aliases.zsh"

__git_colour() {
  command git rev-parse --git-dir &>/dev/null || return 0
  if [[ -n $(command git status --porcelain 2>/dev/null) ]]; then
    print -rn -- '%F{196}'
  else
    print -rn -- '%F{46}'
  fi
}
__gitb() { command git symbolic-ref --quiet --short HEAD 2>/dev/null; }
__git_ps1() {
  local branch=$(__gitb)
  [[ -n $branch ]] && print -rn -- "(${branch//\%/%%})"
}
PS1='%F{146}%n@%m %F{46}%D{%Y-%m-%d} %D{%H:%M:%S}%F{33}${SSH_TTY} %F{88}+${SHLVL} %F{226}%~$(__git_colour)$(__git_ps1) %F{178}($SHLVL:%!)%F{255}$ %f'

# Machine-only functions and aliases take precedence over shared settings.
[[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/ba/local.zsh ]] &&
  source "${XDG_CONFIG_HOME:-$HOME/.config}/ba/local.zsh"
return 0
