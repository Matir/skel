#!/usr/bin/env bash

# shellcheck disable=SC2155,SC2223

set -o nounset
set -o errexit
set -o shwordsplit 2>/dev/null || true  # Make zsh behave like bash

HOME=${HOME:-$(cd ~ && pwd)}
LOCAL_BIN="${HOME}/.local/bin"
STARSHIP_INSTALL_HASH="52c64f14a558034ebeb1907ea9364e802b32474576fd3e68265f73bc33cc8fbb"

# 1. Get the raw script path (handles Bash vs Zsh)
TARGET="${BASH_SOURCE[0]}"

# 2. Loop to resolve symlinks completely
while [ -L "$TARGET" ]; do
  DIR=$(cd -P "$(dirname -- "$TARGET")" &>/dev/null && pwd)
  TARGET=$(readlink "$TARGET")
  # If $TARGET is a relative symlink, resolve it relative to the symlink's directory
  [[ $TARGET != /* ]] && TARGET="$DIR/$TARGET"
done

# 3. Get the final absolute directory
SCRIPT_DIR="$(cd -P "$(dirname -- "$TARGET")" &>/dev/null && pwd)"

have_command() {
  command -v "${1}" >/dev/null 2>&1
}

raw_sha256sum() {
  local file="${1}"
  if [[ -z "${file}" ]]; then
    echo "Error: No file specified" >&2
    return 1
  fi
  if [[ ! -f "${file}" ]]; then
    echo "Error: File not found: ${file}" >&2
    return 1
  fi

  if have_command sha256sum ; then
    sha256sum "${file}" | awk '{print $1}'
  elif have_command shasum ; then
    shasum -a 256 "${file}" | awk '{print $1}'
  else
    echo "Error: Neither sha256sum nor shasum is available" >&2
    return 1
  fi
}

sudo_group() {
  if [[ "$(id -u)" -eq 0 ]] ; then
    return 0
  fi
  have_command sudo && ( id -Gn | grep -q '\bsudo\b' )
}

maybe_sudo() {
  if [[ "$(id -u)" -eq 0 ]] ; then
    "$@"
    return
  fi
  if ! have_command sudo ; then
    return 1
  fi
  sudo "$@"
}

link_directory_contents() {
  local SRCDIR="${1}"
  local DESTDIR="${2}"
  local PREFIX="${3}"
  local file

  # shellcheck disable=SC2086
  find "${SRCDIR}" \( -name .git -o \
                    -name install.sh -o \
                    -name README.md -o \
                    -name .gitignore \) \
      -prune -o -type f -print | \
    while read -r file ; do
      local TARGET="${DESTDIR}/${PREFIX}${file#"${SRCDIR}"/}"
      mkdir -p "$(dirname "${TARGET}")"
      ln -s -f "${file}" "${TARGET}"
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
  local skel_hosts="${BASEDIR}/keys/known_hosts"
  local user_hosts="${HOME}/.ssh/known_hosts"
  local merge_script="${BASEDIR}/skeltools/merge_known_hosts"

  if [[ ! -f "${skel_hosts}" ]]; then
    return 0
  fi

  mkdir -p "${HOME}/.ssh"

  if [[ -f "${user_hosts}" ]]; then
    # User has an existing known_hosts file, merge is required.
    local tmpf
    tmpf="$(mktemp)"
    if [[ -x "${merge_script}" ]]; then
      # Use the robust awk script for merging.
      verbose "Merging known_hosts with authoritative script..."
      "${merge_script}" "${skel_hosts}" "${user_hosts}" > "$tmpf"
    else
      # Fallback to the old, less robust method if the script is missing.
      verbose "Warning: ${merge_script} not found or not executable. Using simple sort."
      cat "${skel_hosts}" "${user_hosts}" | sort -u > "$tmpf"
    fi
    # Safely replace the original file.
    cat "$tmpf" >| "${user_hosts}"
    rm "$tmpf"
  else
    # User does not have a known_hosts file, just copy the new one.
    cp "${skel_hosts}" "${user_hosts}"
  fi
}

install_keys() {
  if [[ -x "${BASEDIR}/bin/update-authorized-keys" ]]; then
    verbose 'Installing SSH keys via update-authorized-keys...'
    printf 'y\n' | "${BASEDIR}/bin/update-authorized-keys"
  fi
  install_gpg_keys
  install_known_hosts
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
  local pref_file="${BASEDIR}/.installed-prefs"
  {
    printf 'BASEDIR=%q\n' "${BASEDIR}"
    printf 'MINIMAL=%q\n' "${MINIMAL}"
    printf 'INSTALL_KEYS=%q\n' "${INSTALL_KEYS}"
    printf 'VERBOSE=%q\n' "${VERBOSE}"
  } >| "$pref_file"
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

install_starship() {
  if have_command starship ; then return 0 ; fi

  if have_command brew ; then
    verbose "Attempting to install Starship via Homebrew..."
    if brew install starship ; then
      return 0
    fi
    echo "brew install starship failed, trying other methods..." >&2
  fi

  if have_command apt-get && sudo_group ; then
    if maybe_sudo apt-get install -qy starship ; then
      return 0
    fi
    echo "apt-get install starship failed, installing locally" >&2
  fi
  local tmpd
  tmpd="$(mktemp -d "${TMPDIR:-/tmp}/starship.XXXXXX")" || return 1

  local install_path="${tmpd}/install.sh"
  if have_command curl ; then
    curl -sSL --show-error -o "${install_path}" https://starship.rs/install.sh
  elif have_command wget ; then
    wget -q -O "${install_path}" --https-only https://starship.rs/install.sh
  else
    echo "No curl or wget available!!" >&2
    rm -rf "${tmpd}"
    return 1
  fi
  local dl_hash
  dl_hash="$(raw_sha256sum "${install_path}")"
  if [[ "$dl_hash" != "${STARSHIP_INSTALL_HASH}" ]] ; then
    echo "Hash check failed!!" >&2
    echo "Expected: ${STARSHIP_INSTALL_HASH}, got ${dl_hash} on ${install_path}" >&2
    rm -rf "${tmpd}"
    return 1
  fi
  if sudo_group ; then
    if maybe_sudo sh "${install_path}" ; then
      rm -rf "${tmpd}"
      return 0
    fi
    echo "root installation failed, falling back to user-local" >&2
  fi
  sh "${install_path}" -b "${LOCAL_BIN}"
  rm -rf "${tmpd}"
}

install_main() {
  if [[ -d "${BASEDIR}/.git" ]] && have_command git ; then
    if [[ -z "$(git -C "${BASEDIR}" status --porcelain)" ]]; then
      git -C "${BASEDIR}" pull --ff-only || true
    else
      echo "Skipping self-update: repository has local changes." >&2
    fi
  fi
  [[ "$MINIMAL" = 1 ]] || {
    mkdir -p "${LOCAL_BIN}"
    install_starship

    # Install vim-plug if not already present
    local VIM_PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    local VIM_AUTOLOAD_DIR="${HOME}/.vim/autoload"
    local VIM_PLUG_FILE="${VIM_AUTOLOAD_DIR}/plug.vim"

    if [[ ! -f "${VIM_PLUG_FILE}" ]]; then
      verbose "Installing vim-plug..."
      mkdir -p "${VIM_AUTOLOAD_DIR}"
      if have_command curl; then
        curl -fsLo "${VIM_PLUG_FILE}" --create-dirs "${VIM_PLUG_URL}"
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
        fi
      done
    fi
  }
  install_dotfiles
  link_directory_contents "${BASEDIR}/bin" "${HOME}/bin" ""

  # macOS specific Homebrew bundle installation
  if [[ "$(uname)" == "Darwin" ]] && have_command brew && [[ -f "${BASEDIR}/Brewfile" ]]; then
    verbose "Checking Homebrew bundle..."
    brew bundle install --file="${BASEDIR}/Brewfile"
  fi

  [[ "$INSTALL_KEYS" = 1 ]] && install_keys
  save_prefs
  cleanup
}


# Setup variables
read_saved_prefs

# Defaults if not passed in or saved.
# TODO: use flags instead of environment variables.
: ${BASEDIR:=${SCRIPT_DIR}}
: ${MINIMAL:=0}
: ${INSTALL_KEYS:=1}
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
  *)
    echo "Unknown operation $OPERATION." >&2
    exit 1
    ;;
esac

echo "OK"
