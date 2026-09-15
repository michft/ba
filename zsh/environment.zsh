# Shared environment. Source from login and interactive Zsh shells.
[[ -n ${_BA_ENV_LOADED-} ]] && return 0
typeset -g _BA_ENV_LOADED=1
export BA_ROOT=${${(%):-%N}:A:h:h}

# Discover either Apple Silicon or Intel Homebrew without fixing a username.
if (( $+commands[brew] )); then
  export HOMEBREW_PREFIX=$(command brew --prefix)
elif [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
elif [[ -x /usr/local/bin/brew ]]; then
  export HOMEBREW_PREFIX=/usr/local
fi

typeset -U path
path=("$HOME/bin" "$HOME/.local/bin" $path)
if [[ -n ${HOMEBREW_PREFIX-} ]]; then
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
  for _ba_dir in "$HOMEBREW_PREFIX/opt/make/libexec/gnubin" "$HOMEBREW_PREFIX/opt/openssl@3/bin"; do
    [[ -d $_ba_dir ]] && path=("$_ba_dir" $path)
  done
  [[ -f $HOMEBREW_PREFIX/etc/ca-certificates/cert.pem ]] &&
    export AWS_CA_BUNDLE=$HOMEBREW_PREFIX/etc/ca-certificates/cert.pem
fi
export BUN_INSTALL=${BUN_INSTALL:-$HOME/.bun}
export PNPM_HOME=${PNPM_HOME:-$HOME/Library/pnpm}
export NVM_DIR=${NVM_DIR:-$HOME/.nvm}
for _ba_dir in "$HOME/.cargo/bin" "$HOME/.lmstudio/bin" "$BUN_INSTALL/bin" "$PNPM_HOME" /Applications/cmux.app/Contents/Resources/bin; do
  [[ -d $_ba_dir ]] && path=("$_ba_dir" $path)
done
unset _ba_dir
export PATH
export VISUAL=${VISUAL:-vim}
export EDITOR=${EDITOR:-$VISUAL}
export HISTTIMEFORMAT='%F %T '
export OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:--1}
# Preserve the terminal's TERM (including cmux's xterm-ghostty).

# Optional machine environment, loaded before completions and tool setup.
[[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/ba/env.zsh ]] &&
  source "${XDG_CONFIG_HOME:-$HOME/.config}/ba/env.zsh"
return 0
