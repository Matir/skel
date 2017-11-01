# Custom plugin to handle gpg-agent 2.1

local GPG_ENV=$HOME/.gnupg/gpg-agent.env

function start_agent_nossh {
    eval $(/usr/bin/env gpg-agent --quiet --daemon --write-env-file ${GPG_ENV} 2> /dev/null)
    chmod 600 ${GPG_ENV}
    export GPG_AGENT_INFO
}

function start_agent_withssh {
    eval $(/usr/bin/env gpg-agent --quiet --daemon --enable-ssh-support --write-env-file ${GPG_ENV} 2> /dev/null)
    chmod 600 ${GPG_ENV}
    export GPG_AGENT_INFO
    export SSH_AUTH_SOCK
    export SSH_AGENT_PID
}

if [ -z "${GPG_AGENT_INFO}" ] ; then
  if which gpgconf >/dev/null 2>&1 ; then
    GPG_AGENT_INFO=$(gpgconf --list-dirs agent-socket)
    export GPG_AGENT_INFO
    if [ -z "${SSH_AUTH_SOCK}" ] ; then
      SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      export SSH_AUTH_SOCK
    fi
  fi
fi

# check if another agent is running
if ! gpg-connect-agent --agent-program /dev/null --quiet /bye > /dev/null 2> /dev/null; then
    # source settings of old agent, if applicable
    if [ -f "${GPG_ENV}" ]; then
        # This can be clobbered by the file
        local OLD_SSH_AUTH_SOCK=${SSH_AUTH_SOCK}
        . ${GPG_ENV} > /dev/null
        export GPG_AGENT_INFO
        export SSH_AUTH_SOCK
        export SSH_AGENT_PID
    fi

    # check again if another agent is running using the newly sourced settings
    if ! gpg-connect-agent --agent-program /dev/null --quiet /bye > /dev/null 2> /dev/null; then
        # check for existing ssh-agent
        if [ -n "${OLD_SSH_AUTH_SOCK}" ] ; then
          SSH_AUTH_SOCK=${OLD_SSH_AUTH_SOCK};export SSH_AUTH_SOCK
        fi
        if ssh-add -l > /dev/null 2> /dev/null; then
            # ssh-agent running, start gpg-agent without ssh support
            start_agent_nossh;
        else
            # otherwise start gpg-agent with ssh support
            start_agent_withssh;
        fi
    fi
fi

GPG_TTY=$(tty)
export GPG_TTY
