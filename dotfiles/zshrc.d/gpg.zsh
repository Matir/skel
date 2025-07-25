if ! which gpg-agent >/dev/null 2>&1 ; then
  return 1
fi

if test -f ${HOME}/.no-gpg-agent ; then
  return 0
fi

# Set the default paths to gpg-agent files.
_gpg_agent_conf="${GNUPGHOME:-$HOME/.gnupg}/gpg-agent.conf"
_gpg_agent_env="${TMPDIR:-/tmp}/gpg-agent.env.$UID"

# Load environment variables from previous run
source "$_gpg_agent_env" 2> /dev/null

# Start gpg-agent if not started.
if [[ -z "$GPG_AGENT_INFO" && ! -S "${GNUPGHOME:-$HOME/.gnupg}/S.gpg-agent" ]]; then
  # Start gpg-agent if not started.
  if ! ps -U "$LOGNAME" -o pid,ucomm | grep -q -- "${${${(s.:.)GPG_AGENT_INFO}[2]}:--1} gpg-agent"; then
    eval "$(gpg-agent --daemon 2>/dev/null | tee "$_gpg_agent_env")"
  fi
fi

# Inform gpg-agent of the current TTY for user prompts.
export GPG_TTY="$(tty)"

# Setup SSH agent support
if grep -q '^enable-ssh-support' "$_gpg_agent_conf" &> /dev/null; then
  # Load required functions.
  autoload -Uz add-zsh-hook

  if test -z "$SSH_AUTH_SOCK" ; then
    SSH_AUTH_SOCK="/run/user/$(id -u)/gnupg/S.gpg-agent.ssh"
    if test -S "$SSH_AUTH_SOCK" ; then
      export SSH_AUTH_SOCK
    else
      unset SSH_AUTH_SOCK
    fi
  fi

  # Updates the GPG-Agent TTY before every command since SSH does not set it.
  function _gpg-agent-update-tty {
    gpg-connect-agent UPDATESTARTUPTTY /bye >/dev/null
  }
  add-zsh-hook preexec _gpg-agent-update-tty
fi

# Clean up.
unset _gpg_agent_{conf,env}

# Disable GUI prompts inside SSH.
if [[ -n "$SSH_CONNECTION" ]]; then
  export PINENTRY_USER_DATA='USE_CURSES=1'
fi
