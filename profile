# Sourced by zshrc as well as bash.

umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    	. "$HOME/.bashrc"
    fi
fi

# Paths and preferences
export PATH="$HOME/bin:/sbin:/usr/sbin:$PATH"
export PYTHONPATH="$HOME/.python"
export VISUAL=vim
export EDITOR=vim
export TZ='America/Los_Angeles'
export DEBEMAIL=david@systemoverlord.com
export DEBFULLNAME="David Tomaschik"


# Setup GPG Agent
GPG_AGENT_INFO_PATH=$HOME/.gnupg/gpg-agent-info-`hostname`
if test -f $GPG_AGENT_INFO_PATH && kill -0 `cut -d: -f 2 $GPG_AGENT_INFO_PATH` 2>/dev/null ; then
  . $GPG_AGENT_INFO_PATH
  export GPG_AGENT_INFO SSH_AUTH_SOCK SSH_AGENT_PID
else
  gpg-agent -q || eval `gpg-agent --daemon --enable-ssh-support --write-env-file $GPG_AGENT_INFO_PATH` 2>/dev/null
fi
unset GPG_AGENT_INFO_PATH
export GPG_TTY=`tty`
# End GPG

if [ -e $HOME/.localenv ] ; then source $HOME/.localenv ; fi
if [[ $- == *i* ]] && [[ -e $HOME/.aliases ]] ; then source $HOME/.aliases ; fi
