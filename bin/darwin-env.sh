#!/bin/sh

set -o nounset

TMP_DIR="${TMPDIR:-/tmp}"
TMP_DIR="${TMP_DIR%/}"

env > "${TMP_DIR}/env-pre" 2>/dev/null || true
if [ -f "${HOME}/.shenv" ]; then
  . "${HOME}/.shenv"
fi
env > "${TMP_DIR}/env-post" 2>/dev/null || true

if [ -x "/bin/launchctl" ]; then
  for VAR in $(env | awk -F= '/^[a-zA-Z_][a-zA-Z0-9_]*=/ {print $1}') ; do
    case "${VAR}" in
      _|""|*[!a-zA-Z0-9_]*|[0-9]*) continue ;;
    esac
    eval "val=\${${VAR}:-}"
    /bin/launchctl setenv "${VAR}" "${val}"
  done
fi
