# Sourced by zshrc as well as bash.

umask 022
ulimit -c unlimited

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
export GOPATH="$HOME/.go"
export VISUAL=vim
export EDITOR=vim
export TZ='America/Los_Angeles'
export DEBEMAIL=david@systemoverlord.com
export DEBFULLNAME="David Tomaschik"

# GCE?
if [ -d $HOME/.gce/google-cloud-sdk/bin ] ; then
  export PATH="$PATH:$HOME/.gce/google-cloud-sdk/bin"
fi

# Setup GPG Agent
GPG_AGENT_INFO_PATH=$HOME/.gnupg/gpg-agent-info-`hostname`
if test -f $GPG_AGENT_INFO_PATH && kill -0 `cut -d: -f 2 $GPG_AGENT_INFO_PATH` 2>/dev/null ; then
  . $GPG_AGENT_INFO_PATH
  export GPG_AGENT_INFO SSH_AUTH_SOCK SSH_AGENT_PID
else
  if which gpg-agent >/dev/null 2>&1 ; then
    gpg-agent -q || eval `gpg-agent --daemon --enable-ssh-support --write-env-file $GPG_AGENT_INFO_PATH` 2>/dev/null
  fi
fi
unset GPG_AGENT_INFO_PATH
export GPG_TTY=`tty`
# End GPG

if [ -e $HOME/.localenv ] ; then source $HOME/.localenv ; fi
if [[ $- == *i* ]] && [[ -e $HOME/.aliases ]] ; then source $HOME/.aliases ; fi
