function dumpenv {
  tr '\0' '\n' < /proc/${1}/environ
}

if test -x "/sbin/starship" ; then
  _STARSHIP_PATH="/sbin/starship"
  function starship_prompt {
    eval "$(/sbin/starship init zsh)"
  }
elif test -x "${HOME}/tools/starship/starship" ; then
  _STARSHIP_PATH="${HOME}/tools/starship/starship"
  function starship_prompt {
    eval "$($HOME/tools/starship/starship init zsh)"
  }
fi
if test -f ${HOME}/.zprompt ; then
  if test "$(cat ${HOME}/.zprompt)" = "starship" ; then
    if test -n "${_STARSHIP_PATH:-}" ; then
      eval "$(${_STARSHIP_PATH} init zsh)"
    fi
  fi
fi
unset _STARSHIP_PATH

function hashall {
  tee >(md5sum) | tee >(sha1sum) | sha256sum
}

function rtmux {
  if [ "$#" -lt 1 ] ; then
    echo "Usage: $0 <host> [tmux args]" >&2
    return 1
  fi
  HOST="${1}"
  shift
  ssh -t ${HOST} -- tmux "$@"
}

function generate_secure_key {
  local BITS=128
  local FORMAT=b64
  for arg in "$@" ; do
    if [[ "${arg}" =~ '^[0-9]+$' ]] ; then
      BITS="${arg}"
    elif [[ "${arg:l}" == "b64" ]] ; then
      FORMAT=b64
    elif [[ "${arg:l}" == "hex" ]] ; then
      FORMAT=hex
    else
      echo "Unknown argument $arg" >&2
      return 1
    fi
  done
  if [[ "${BITS}" -lt 64 ]] ; then
    echo "Refusing to create a key less than 64 bits!" >&2
    return 1
  fi
  local ENCODE
  case "${FORMAT}" in
    b64)
      case "${OSTYPE}" in
        darwin*)
          ENCODE="base64 -b 0"
          ;;
        linux*)
          ENCODE="base64 -w 0; echo"
          ;;
        *)
          ;;
      esac
      ;;
    hex)
      ENCODE="xxd -ps -c 0"
      ;;
    *)
      echo "Unknown encoding ${FORMAT}" >&2
      return 1
  esac
  local BYTES=$((BITS/8))
  head -c "${BYTES}" /dev/urandom | ${(s: :)ENCODE}
}
