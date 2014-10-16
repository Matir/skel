# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory autocd autopushd extendedglob nohup nomatch histignorespace
unsetopt beep
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/david/.zshrc'

autoload -Uz compinit && compinit
# End of lines added by compinstall

DIRSTACKSIZE=16
case $TERM in
  xterm*)
    precmd () {print -Pn "\e]0;%n@%m: %~\a"}
    ;;
esac

autoload -U colors && colors
PS1="%{%(!.$fg[red].$fg[green])%}%n%{$fg[white]%}@%{$fg[cyan]%}%m%{$fg[white]%}:%{$fg[green]%}%32<...<%~%<<%{$fg[white]%}%#%{$reset_color%} "

. ~/.profile
# Deduplicate the path
typeset -U path

alias ls='ls --color'

# Load oh-my-zsh
if [ -d $HOME/.oh-my-zsh ] ; then
  ZSH=$HOME/.oh-my-zsh
  ZSH_THEME="matir"
  ORIG_PS1="${PS1}"
  if [[ ! -a $ZSH/themes/$ZSH_THEME ]] ; then
    ZSH_THEME=""
  fi
  plugins=(git encode64 gpg-agent pep8 pip python tmux urltools extract sudo)
  source $ZSH/oh-my-zsh.sh
  unset ZSH_THEME
  if [[ "$PS1" == "%n@%m:%~%# " ]] ; then
    PS1="${ORIG_PS1}"
  fi
  unset ORIG_PS1
fi

# Keybindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
