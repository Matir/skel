#!/bin/sh
# shellcheck disable=SC1090

# common functions for use in shell scripts

find_first() {
  while [ "$#" -gt 0 ]; do
    if test -e "${1}" ; then
      echo "${1}"
      return 0
    fi
    shift
  done
  return 1
}

have_command() {
  command -v "$1" >/dev/null 2>&1
}

# Helper function: Returns 0 if the directory is in PATH, 1 otherwise
path_contains() {
  case ":${PATH}:" in
    *:"$1":*) return 0 ;;
    *)        return 1 ;;
  esac
}

# Prepend a directory to PATH if it's not already there
path_prepend() {
  if [ -d "$1" ] && ! path_contains "$1"; then
    PATH="$1:${PATH}"
  fi
}

# Append a directory to PATH if it's not already there
path_append() {
  if [ -d "$1" ] && ! path_contains "$1"; then
    PATH="${PATH}:$1"
  fi
}

source_first_existing() {
  _sfe_script="$(find_first "$@")"
  _sfe_status=$?

  if [ "$_sfe_status" -eq 0 ]; then
    . "$_sfe_script"
    # Clean up our temporary variables before returning success
    unset -v _sfe_script _sfe_status
    return 0
  fi

  # Clean up our temporary variables before returning failure
  unset -v _sfe_script _sfe_status
  return 1
}

source_if_existing() {
  if [ -f "$1" ]; then
    . "$1"
  fi
}
