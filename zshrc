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
  ZSH_CUSTOM="$HOME/.zsh_custom"
  plugins=(git encode64 gpg-agent pep8 pip python tmux urltools extract sudo virsh virtualenv)
  source $ZSH/oh-my-zsh.sh
  unset ZSH_THEME
fi

# Keybindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# SSH autocompletion
# ssh, scp, ping, host
# https://github.com/tehmaze/maze.io/blob/master/maze/_post/2008/08-03-remote-tabcompletion-using-openssh-and-zsh.md
zstyle ':completion:*:scp:*' tag-order 'hosts:-host hosts:-domain:domain hosts:-ipaddr:IP\ address *'
zstyle ':completion:*:scp:*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order users 'hosts:-host hosts:-domain:domain hosts:-ipaddr:IP\ address *'
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp):*:hosts-host' ignored-patterns '*.*' loopback localhost
zstyle ':completion:*:(ssh|scp):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^*.*' '*@*'
zstyle ':completion:*:(ssh|scp):*:hosts-ipaddr' ignored-patterns '^<->.<->.<->.<->' '127.0.0.<->'
zstyle ':completion:*:(ssh|scp):*:users' ignored-patterns adm bin daemon halt lp named shutdown sync
zstyle -e ':completion:*:(ssh|scp):*' hosts 'reply=(
      ${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) \
                      /dev/null)"}%%[# ]*}//,/ }
      ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
      ${=${${${${(@M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#*\**}:#*\?*}}
      )'

# Load any local settings
if [ -e $HOME/.zshrc.local ] ; then source $HOME/.zshrc.local ; fi
