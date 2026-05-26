function dumpenv {
  if [ "$(uname)" = "Linux" ]; then
    tr '\0' '\n' < /proc/${1}/environ
  elif [ "$(uname)" = "Darwin" ]; then
    # macOS doesn't have /proc, use ps instead.
    # Note: this may truncate if environment is very large.
    ps -p ${1} -wwwe -o command= | tr ' ' '\n' | grep '='
  fi
}

_STARSHIP_PATH="$(find_first "$(command -v starship)" /sbin/starship "${HOME}/tools/starship/starship" "${HOME}/.local/bin/starship" /usr/local/bin/starship)"
if test -n "$_STARSHIP_PATH" ; then
  function starship_prompt {
    eval "$($_STARSHIP_PATH init zsh)"
  }
fi

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
