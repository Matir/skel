layout_python() {
  local DIR_NAME="$(basename $(pwd))"
  VIRTUAL_ENV="${VIRTUAL_ENV:-$(pwd)/.venv/${DIR_NAME}}"
  local PYBIN="$(command -v python 2>/dev/null || command -v python3 2>/dev/null)"
  if [[ -z "${PYBIN}" ]]; then
    log_error "No python found!"
    return 1
  fi
  if [[ ! -d $VIRTUAL_ENV ]]; then
    log_status "No virtual environment exists. Executing \`${PYBIN} -m venv ${VIRTUAL_ENV}\`."
    "${PYBIN}" -m venv "${VIRTUAL_ENV}"
  fi

  # Activate the virtual environment
  . $VIRTUAL_ENV/bin/activate
}
