#!/usr/bin/env bash

# shellcheck disable=SC2155,SC2223

set -o nounset
set -o errexit
set -o shwordsplit 2>/dev/null || true  # Make zsh behave like bash

HOME=${HOME:-$(cd ~ && pwd)}

case $(uname) in
  Linux)
    FINDTYPE="-xtype"
    ;;
  Darwin|*BSD)
    FINDTYPE="-type"
    ;;
  *)
    echo "Unknown OS: $(uname), guessing no GNU utils."
    FINDTYPE="-type"
    ;;
esac

have_command() {
  command -v "${1}" >/dev/null 2>&1
}

prerequisites() {
  local USER=${USER:-$(id -un)}
  if have_command zsh ; then
    case $- in
      *i*)
        local shell_path
        if [[ "$(uname)" = "Darwin" ]]; then
          # dscl output is "UserShell: /bin/zsh"
          shell_path="$(dscl . -read "/Users/${USER}" UserShell | awk '{print $2}')"
        else
          shell_path="$(getent passwd "${USER}" | cut -d: -f7)"
        fi
        case "${shell_path}" in
          */zsh)
            ;;
          *)
            echo "Your login shell is not zsh. To change it, run:" >&2
            echo "chsh -s $(command -v zsh)" >&2
            ;;
        esac
        ;;
    esac
  else
    echo "ZSH not found!" >&2
  fi
}

link_directory_contents() {
  local SRCDIR="${1}"
  local DESTDIR="${2}"
  local PREFIX="${3}"
  local file
  local submodule_prune=""

  # Submodule logic only applies when we are installing dotfiles (PREFIX=".")
  if [[ "${PREFIX}" == "." ]]; then
    submodule_prune="$(git -C "${BASEDIR}" submodule status -- "${SRCDIR}" 2>/dev/null | \
      awk '{print $2}' | \
      while read -r submod ; do
        echo -n " -o -path ${BASEDIR}/${submod}"
      done)"
  fi

  # shellcheck disable=SC2086
  find "${SRCDIR}" \( -name .git -o \
                    -name install.sh -o \
                    -name README.md -o \
                    -name .gitignore \
                    ${submodule_prune} \) \
      -prune -o ${FINDTYPE} f -print | \
    while read -r file ; do
      local TARGET="${DESTDIR}/${PREFIX}${file#"${SRCDIR}"/}"
      mkdir -p "$(dirname "${TARGET}")"
      ln -s -f "${file}" "${TARGET}"
    done

  # Submodule logic only applies when we are installing dotfiles (PREFIX=".")
  if [[ "${PREFIX}" == "." ]]; then
    git -C "${BASEDIR}" submodule status -- "${SRCDIR}" 2>/dev/null | \
      awk '{print $2}' | \
      while read -r submodule ; do
        local FULLNAME="${BASEDIR}/${submodule}"
        local TARGET="${DESTDIR}/${PREFIX}${FULLNAME#"${SRCDIR}"/}"
        mkdir -p "$(dirname "${TARGET}")"
        if [[ -L "${TARGET}" ]] ; then
          if [[ "$(readlink "${TARGET}")" != "${FULLNAME}" ]] ; then
            echo "${TARGET} points to $(readlink "${TARGET}") not ${FULLNAME}!" >/dev/stderr
          fi
        elif [[ -d "${TARGET}" ]] ; then
          echo "rm -rf ${TARGET}" >/dev/stderr
        else
          ln -s -f "${FULLNAME}" "${TARGET}"
        fi
      done
  fi
}

ssh_key_already_installed() {
  # Return 1 if the key isn't already installed, 0 if it is
  local AK="${HOME}/.ssh/authorized_keys"
  if [[ ! -f "$AK" ]] ; then
    return 1
  fi
  # Extract the key data (field 2) from the key file, ignoring comments
  local key_data
  key_data=$(awk '/^ssh-/ {print $2}' "$1")
  if [[ -z "${key_data}" ]]; then
    # Not a valid key file
    return 1
  fi
  # Use grep with fixed-string matching to see if the key is present.
  # The exit code of grep is 0 on match, 1 on no match, which is perfect.
  grep -F -q -- "${key_data}" "${AK}"
}

install_ssh_keys() {
  # Install SSH keys
  verbose 'Installing SSH keys...'
  local AK="${HOME}/.ssh/authorized_keys"
  local key
  local keydir
  if [[ "${TRUST_ALL_KEYS}" = 1 ]] ; then
    keydir="${BASEDIR}/keys/ssh"
  else
    keydir="${BASEDIR}/keys/ssh/trusted"
  fi
  for key in "${keydir}"/* ; do
    if [[ ! -f "${key}" ]] ; then
      continue
    fi
    if ssh_key_already_installed "${key}" ; then
      verbose "Key $(basename "${key}") already installed..."
      continue
    fi
    echo "# $(basename "${key}") added from skel on $(date +%Y-%m-%d)" >> "${AK}"
    cat "${key}" >> "${AK}"
  done
}

install_gpg_keys() {
  have_command gpg || \
    return 0
  local key
  for key in "${BASEDIR}"/keys/gpg/* ; do
    gpg --import < "${key}" >/dev/null 2>&1
  done
}

install_known_hosts() {
  verbose 'Installing known hosts...' >&2
  if [[ ! -f "${BASEDIR}/keys/known_hosts" ]] ; then
    return 0
  fi
  mkdir -p "${HOME}/.ssh"
  if [[ -f "${HOME}/.ssh/known_hosts" ]] ; then
    local tmpf="$(mktemp)"
    cat "${BASEDIR}"/keys/known_hosts "${HOME}"/.ssh/known_hosts \
      | sort -u > "$tmpf"
    mv "$tmpf" "${HOME}"/.ssh/known_hosts
  else
    cp "${BASEDIR}"/keys/known_hosts "${HOME}"/.ssh/known_hosts
  fi
}

install_keys() {
  install_ssh_keys
  install_gpg_keys
  install_known_hosts
}

setup_git_email() {
  local gc_local="${HOME}/.gitconfig.local"
  local current_email=""

  if [[ -f "${gc_local}" ]]; then
    current_email=$(git config -f "${gc_local}" user.email || true)
  fi

  if [[ -n "${GIT_EMAIL:-}" ]]; then
    # Use environment variable
    git config -f "${gc_local}" user.email "${GIT_EMAIL}"
  elif [[ -n "${current_email}" ]]; then
    # Already has an email set
    GIT_EMAIL="${current_email}"
  else
    # Prompt the user
    echo -n "Enter git email (leave blank to skip): " >&2
    read -r GIT_EMAIL || true
    if [[ -n "${GIT_EMAIL}" ]]; then
      git config -f "${gc_local}" user.email "${GIT_EMAIL}"
    fi
  fi
  export GIT_EMAIL
}

read_saved_prefs() {
  # Can't use basedir here as we don't have it yet
  local pref_file="$(dirname "$0")/.installed-prefs"
  if [[ -f "${pref_file}" ]] ; then
    verbose "Loading saved skel preferences from ${pref_file}"
    # source is a bashism
    # shellcheck disable=SC1090
    . "${pref_file}"
  fi
}

save_prefs() {
  [[ "$SAVE" = 1 ]] || return 0
  local pref_file=${BASEDIR}/.installed-prefs
  {
    echo "BASEDIR=\"${BASEDIR}\""
    echo "MINIMAL=\"${MINIMAL}\""
    echo "INSTALL_KEYS=\"${INSTALL_KEYS}\""
    echo "TRUST_ALL_KEYS=\"${TRUST_ALL_KEYS}\""
    echo "VERBOSE=\"${VERBOSE}\""
  } > "$pref_file"
}

cleanup() {
  if [[ -x "${BASEDIR}/bin/prune-broken-symlinks.sh" ]]; then
    "${BASEDIR}/bin/prune-broken-symlinks.sh" -y "${HOME}/.zshrc.d"
    "${BASEDIR}/bin/prune-broken-symlinks.sh" -y "${HOME}/bin"
  fi
}

verbose() {
  [[ "${VERBOSE:-0}" = 1 ]] && echo "$@" >&2 || return 0
}

# Operations

install_dotfiles() {
  link_directory_contents "${BASEDIR}/dotfiles" "${HOME}" "."
  if [[ -d "${BASEDIR}/local_dotfiles" ]] ; then
    link_directory_contents "${BASEDIR}/local_dotfiles" "${HOME}" "."
  fi
  if [[ -d "${BASEDIR}/dotfile_overlays" ]] ; then
    for dotfiledir in "${BASEDIR}/dotfile_overlays/"* ; do
      if [[ -d "${dotfiledir}" ]] ; then
        link_directory_contents "${dotfiledir}" "${HOME}" "."
      fi
    done
  fi
}

install_main() {
  if [[ -d "${BASEDIR}/.git" && have_command git ]] ; then
    if [[ -z "$(git -C "${BASEDIR}" status --porcelain)" ]]; then
      git -C "${BASEDIR}" pull --ff-only || true
    else
      echo "Skipping self-update: repository has local changes." >&2
    fi
  fi
  [[ "$MINIMAL" = 1 ]] || {
    prerequisites

    # Install vim-plug if not already present
    local VIM_PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    local VIM_AUTOLOAD_DIR="${HOME}/.vim/autoload"
    local VIM_PLUG_FILE="${VIM_AUTOLOAD_DIR}/plug.vim"

    if [[ ! -f "${VIM_PLUG_FILE}" ]]; then
      verbose "Installing vim-plug..."
      mkdir -p "${VIM_AUTOLOAD_DIR}"
      if have_command curl; then
        curl -fLo "${VIM_PLUG_FILE}" --create-dirs "${VIM_PLUG_URL}"
      else
        echo "Error: curl not found. Cannot install vim-plug." >&2
      fi
        fi
    
        # Install TPM (Tmux Plugin Manager) if not already present
        local TPM_DIR="${HOME}/.tmux/plugins/tpm"
        local TPM_REPO="https://github.com/tmux-plugins/tpm"
    
        if [[ ! -d "${TPM_DIR}" ]]; then
          verbose "Installing TPM (Tmux Plugin Manager)..."
          if have_command git; then
            git clone --depth 1 "${TPM_REPO}" "${TPM_DIR}"
          else
            echo "Error: git not found. Cannot install TPM." >&2
          fi
        fi
    
        # try to update dotfile overlays
    if [[ -d "${BASEDIR}/dotfile_overlays" ]] ; then
      for dotfiledir in "${BASEDIR}/dotfile_overlays/"* ; do
        if [[ -d "${dotfiledir}/.git" ]] ; then
          git -C "${dotfiledir}" pull --ff-only || true
          git -C "${dotfiledir}" submodule update --init --recursive --depth 1 || true
        fi
      done
    fi
  }
  install_dotfiles
  link_directory_contents "${BASEDIR}/bin" "${HOME}/bin" ""
  [[ "$INSTALL_KEYS" = 1 ]] && install_keys
  save_prefs
  setup_git_email
  cleanup
}

install_vim_extra() {
  local DEST="${HOME}/.vim/pack/matir-extra"
  local REPO="https://github.com/Matir/vim-extra.git"

  if [[ -d "${DEST}" ]] ; then
    if [[ -d "${DEST}/.git" ]] ; then
      # do update
      git -C "${DEST}" pull --ff-only
      git -C "${DEST}" submodule update --init
    else
      echo "${DEST} exists but does not appear to be a git repo." >&2
      return 1
    fi
  else
    # do clone
    git clone --recurse-submodules "${REPO}" "${DEST}"
  fi
}

# Setup variables
read_saved_prefs

# Defaults if not passed in or saved.
# TODO: use flags instead of environment variables.
: ${BASEDIR:=$HOME/.skel}
: ${MINIMAL:=0}
: ${INSTALL_KEYS:=1}
: ${TRUST_ALL_KEYS:=0}
: ${VERBOSE:=0}
: ${SAVE:=1}

# Check prerequisites
if [[ ! -d "$BASEDIR" ]] ; then
  echo "Please install to $BASEDIR!" 1>&2
  exit 1
fi

OPERATION=${1:-install}

case $OPERATION in
  install)
    install_main
    ;;
  dotfiles)
    install_dotfiles
    ;;
  vim-extra)
    # Install/update extra vim modules
    install_vim_extra
    ;;
  *)
    echo "Unknown operation $OPERATION." >&2
    exit 1
    ;;
esac

echo "OK"
