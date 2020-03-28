LOGGER_ENV=""
LOGGER_DIR="${LOGGER_DIR:-${HOME}/.zlogs}"

function _logger_now {
  print -P "%D{%Y%m%d-%H%M%S}"
}

function logenv {
  LOGGER_ENV="${1:-}"
  if test -z "${LOGGER_ENV}" ; then
    return 0
  fi
  mkdir -p "${LOGGER_DIR}/${LOGGER_ENV}"
}

# Executed on prompt
function _logger_precmd {
  _RV="$?"
  if test -z "${LOGGER_ENV}" ; then
    return 0
  fi
  _LOGGER_STOP="$(_logger_now)"
  _LOGGER_DATE="$(print -P '%D{%Y%m%d}')"
  echo "$_LOGGER_START $_LOGGER_STOP $$ $_RV $_LOGGER_CMD" >>| \
    "${LOGGER_DIR}/${LOGGER_ENV}/${_LOGGER_DATE}.log"
  return 0
}

# Executed on command entry
function _logger_preexec {
  _LOGGER_CMD="${2}"
  _LOGGER_START="$(_logger_now)"
  return 0
}

typeset -a precmd_functions
precmd_functions+=_logger_precmd
typeset -a preexec_functions
preexec_functions+=_logger_preexec
