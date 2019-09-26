#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o shwordsplit 2>/dev/null || true  # Make zsh behave like bash

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

is_comment() {
  if [ $(echo "${1}" | cut -c1-1) = '#' ] ; then
    true
  else
    false
  fi
}

prerequisites() {
  if which zsh > /dev/null 2>&1 ; then
    case $- in
      *i*)
        case `getent passwd $USER | cut -d: -f7` in
          */zsh)
            ;;
          *)
            if [ `id` -ne 0 ] ; then
              echo 'Enter password to change shell.' >&2
            fi
            chsh -s `which zsh`
            ;;
        esac
        ;;
    esac
  else
    echo "ZSH not found!" >&2
  fi
}

install_dotfile_dir() {
  local SRCDIR="${1}"
  local dotfile
  local submodule_prune="$(git -C "${BASEDIR}" submodule status -- "${SRCDIR}" 2>/dev/null | \
    awk '{print $2}' | \
    while read submod ; do
      echo -n " -o -path ${BASEDIR}/${submod}"
    done)"
  find "${SRCDIR}" \( -name .git -o \
                    -path "${SRCDIR}/private_dotfiles" -o \
                    -name install.sh -o \
                    -name README.md -o \
                    -name .gitignore \
                    ${submodule_prune} \) \
      -prune -o ${FINDTYPE} f -print | \
    while read dotfile ; do
      local TARGET="${HOME}/.${dotfile#${SRCDIR}/}"
      mkdir -p $(dirname "${TARGET}")
      ln -s -f "${dotfile}" "${TARGET}"
    done
  git submodule status -- "${SRCDIR}" 2>/dev/null | \
    awk '{print $2}' | \
    while read submodule ; do
      local FULLNAME="${BASEDIR}/${submodule}"
      local TARGET="${HOME}/.${FULLNAME#${SRCDIR}/}"
      mkdir -p $(dirname "${TARGET}")
      if test -L "${TARGET}" ; then
        if [ "$(readlink "${TARGET}")" != "${FULLNAME}" ] ; then
          echo "${TARGET} points to $(readlink "${TARGET}") not ${FULLNAME}!" >/dev/stderr
        fi
      elif test -d "${TARGET}" ; then
        echo "rm -rf ${TARGET}" >/dev/stderr
      else
        ln -s -f "${FULLNAME}" "${TARGET}"
      fi
    done
}

install_basic_dir() {
  local SRCDIR="${1}"
  local DESTDIR="${2}"
  local file
  find "${SRCDIR}" ${FINDTYPE} f -print | \
    while read file ; do
    local TARGET="${2}/${file#${SRCDIR}/}"
    mkdir -p `dirname "${TARGET}"`
    ln -s -f "${file}" "${TARGET}"
  done
}

install_git() {
  # Install or update a git repository
  if ! which git > /dev/null ; then
    return 1
  fi
  local REPO="${*: -2:1}"
  local DESTDIR="${*: -1:1}"
  set -- ${@:1:$(($#-2))}
  if [ -d ${DESTDIR}/.git ] ; then
    ( cd ${DESTDIR} ; git pull -q )
  else
    if [ ${MINIMAL} -eq 1 ] ; then
      git clone --depth 1 $* ${REPO} ${DESTDIR}
    else
      git clone $* ${REPO} ${DESTDIR}
    fi
  fi
}

add_bin_symlink() {
  local LINKNAME=${HOME}/bin/${2:-`basename $1`}
  if [ -e ${LINKNAME} -a ! -h ${LINKNAME} ] ; then
    echo "Refusing to overwrite ${LINKNAME}" >&2
    return 1
  fi
  ln -sf ${1} ${LINKNAME}
}

postinstall() {
  true
}

ssh_key_already_installed() {
  # Return 1 if the key isn't already installed, 0 if it is
  local AK="${HOME}/.ssh/authorized_keys"
  if [ ! -f $AK ] ; then
    return 1
  fi
  local KEYFP=`ssh-keygen -l -f $1 2>/dev/null | awk '{print $2}'`
  local TMPF=`mktemp`
  local key
  while read key ; do
    if is_comment "${key}" ; then
      continue
    fi
    echo "$key" > $TMPF
    local EFP=`ssh-keygen -l -f ${TMPF} 2>/dev/null | awk '{print $2}'`
    if [ "$EFP" = "$KEYFP" ] ; then
      rm $TMPF 2>/dev/null
      return 0
    fi
  done < ${AK}
  rm $TMPF 2>/dev/null
  return 1
}

install_ssh_keys() {
  # Install SSH keys
  verbose 'Installing SSH keys...'
  local AK="${HOME}/.ssh/authorized_keys"
  local key
  local keydir
  if test ${TRUST_ALL_KEYS} = 1 ; then
    keydir=${BASEDIR}/keys/ssh
  else
    keydir=${BASEDIR}/keys/ssh/trusted
  fi
  for key in ${keydir}/* ; do
    if [ ! -f "${key}" ] ; then
      continue
    fi
    if ssh_key_already_installed "${key}" ; then
      verbose "Key `basename ${key}` already installed..."
      continue
    fi
    echo "# `basename ${key}` added from skel on `date +%Y-%m-%d`" >> ${AK}
    cat ${key} >> ${AK}
  done
}

install_gpg_keys() {
  which gpg >/dev/null 2>&1 || \
    return 0
  local key
  for key in ${BASEDIR}/keys/gpg/* ; do
    gpg --import < ${key} >/dev/null
  done
}

install_known_hosts() {
  verbose 'Installing known hosts...' >&2
  if [ ! -f "${BASEDIR}/keys/known_hosts" ] ; then
    return 0
  fi
  mkdir -p ${HOME}/.ssh
  if [ -f "${HOME}/.ssh/known_hosts" ] ; then
    local tmpf=`mktemp`
    cat ${BASEDIR}/keys/known_hosts ${HOME}/.ssh/known_hosts | sort -u > $tmpf
    mv $tmpf ${HOME}/.ssh/known_hosts
  else
    cp ${BASEDIR}/keys/known_hosts ${HOME}/.ssh/known_hosts
  fi
}

install_keys() {
  install_ssh_keys
  install_gpg_keys
  install_known_hosts
}

is_deb_system() {
  test -f /usr/bin/apt-get
}

run_as_root() {
  # Attempt to run as root
  if [ ${USER} = "root" ] ; then
    "$@"
    return $?
  elif test -x $(which sudo 2>/dev/null) ; then
    verbose "Using sudo to run ${1}..."
    sudo "$@"
    return $?
  fi
  return 1
}

install_pkg_set() {
  local pkg_file=${BASEDIR}/${1}
  local pkg_list=""
  if [ ! -f "${pkg_file}" ] ; then
    echo "Package set $(basename ${pkg_file}) does not exist." 1>&2
    return 1
  fi
  while read line ; do
    if is_comment "${line}" ; then
      continue
    fi
    if [ -z "${line}" ] ; then
      continue
    fi
    if apt-cache show ${line} >/dev/null 2>&1 ; then
      pkg_list="${pkg_list} ${line}"
    else
      echo "Warning: package ${line} not found." >&2
    fi
  done < ${pkg_file}
  if [ -n "${pkg_list}" ] ; then
    verbose "Installing ${pkg_list}"
    run_as_root apt-get install -qqy ${pkg_list}
  fi
}

install_apt_pkgs() {
  run_as_root apt-get update -qq || \
    ( echo "Can't run apt-get commands" >&2 && \
      return 1 )
  install_pkg_set packages.minimal
  if test $MINIMAL = 1 ; then
    return 0
  fi
  test $HAVE_X = 1 && install_pkg_set packages.X
  test $IS_KALI = 1 && install_pkg_set packages.kali
  install_pkg_set packages.${ARCH}
  test $HAVE_X = 1 && install_chrome
}

install_chrome() {
  local TMPD=`mktemp -d`
  local CHROME_ARCH=`echo ${ARCH} | sed 's/x86_64/amd64/'`
  dpkg-query -l 'google-chrome*' >/dev/null 2>&1 && return 0
  /usr/bin/wget --quiet -O ${TMPD}/google-chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-beta_current_${CHROME_ARCH}.deb
  run_as_root /usr/bin/dpkg -i ${TMPD}/google-chrome.deb || \
    run_as_root /usr/bin/apt-get install -qq -f -y || \
    ( echo "Could not install chrome." >&2 && return 1 )
  rm -rf ${TMPD}
}

read_saved_prefs() {
  # Can't use basedir here as we don't have it yet
  local old_pref_file=`dirname $0`/installed-prefs
  local pref_file=`dirname $0`/.installed-prefs
  if [ -f ${old_pref_file} -a ! -f ${pref_file} ] ; then
    mv ${old_pref_file} ${pref_file}
  fi
  if [ -f ${pref_file} ] ; then
    verbose "Loading saved skel preferences from ${pref_file}"
    # source is a bashism
    . ${pref_file}
  fi
}

save_prefs() {
  test $SAVE = 1 || return 0
  local pref_file=${BASEDIR}/.installed-prefs
  (echo_pref BASEDIR
   echo_pref MINIMAL
   echo_pref INSTALL_KEYS
   echo_pref TRUST_ALL_KEYS
   echo_pref INSTALL_PKGS
   echo_pref VERBOSE) > $pref_file
}

echo_pref() {
  eval "local val=\${$1}"
  echo "$1=\${$1:-${val}}"
}

cleanup() {
  # Needs zsh
  if ! test -x /usr/bin/zsh ; then
    return 0
  fi
  /usr/bin/zsh >/dev/null 2>&1 <<EOF
  source ${BASEDIR}/dotfiles/zshrc.d/prune-broken-symlinks.zsh
  prune-broken-symlinks -y ${HOME}/.zshrc.d
  prune-broken-symlinks -y ${HOME}/bin
EOF
}

verbose() {
  test ${VERBOSE:-0} = 1 && echo "$@" >&2 || return 0
}

# Operations

install_dotfiles() {
  install_dotfile_dir "${BASEDIR}/dotfiles"
  test -d "${BASEDIR}/private_dotfiles" && \
    test -d "${BASEDIR}/.git/git-crypt" && \
    install_dotfile_dir "${BASEDIR}/private_dotfiles" || \
    true
  test -d "${BASEDIR}/local_dotfiles" && \
    install_dotfile_dir "${BASEDIR}/local_dotfiles" || \
    true
}

install_main() {
  test $MINIMAL = 1 || command -v git >/dev/null 2>&1 && \
    git -C ${BASEDIR} submodule update --init --recursive
  test $MINIMAL = 1 || prerequisites
  test $INSTALL_PKGS = 1 && is_deb_system && install_apt_pkgs
  install_dotfiles
  install_basic_dir "${BASEDIR}/bin" "${HOME}/bin"
  test $MINIMAL = 1 || postinstall
  test $INSTALL_KEYS = 1 && install_keys
  save_prefs
  cleanup
}

install_dconf() {
  which dconf >/dev/null 2>&1 || return 1
  find "${BASEDIR}/dconf" -type f -printf '/%P\n' | while read dcpath ; do
    dconf load ${dcpath}/ < "${BASEDIR}/dconf/${dcpath}"
  done
}

# Setup variables
read_saved_prefs

# Defaults if not passed in or saved.
# TODO: use flags instead of environment variables.
BASEDIR=${BASEDIR:-$HOME/.skel}
MINIMAL=${MINIMAL:-0}
INSTALL_KEYS=${INSTALL_KEYS:-1}
TRUST_ALL_KEYS=${TRUST_ALL_KEYS:-0}
INSTALL_PKGS=${INSTALL_PKGS:-0}
VERBOSE=${VERBOSE:-0}
SAVE=${SAVE:-1}

# Check prerequisites
if [ ! -d $BASEDIR ] ; then
  echo "Please install to $BASEDIR!" 1>&2
  exit 1
fi

if which dpkg-query > /dev/null 2>&1 ; then
  HAVE_X=$(dpkg-query -s xserver-xorg 2>/dev/null | \
    grep -c 'Status.*installed' \
    || true)
else
  HAVE_X=0
fi

IS_KALI=$(grep -ci kali /etc/os-release 2>/dev/null || true)
ARCH=$(uname -m)

OPERATION=${1:-install}

case $OPERATION in
  install)
    install_main
    ;;
  dotfiles)
    install_dotfiles
    ;;
  package*)
    PKG_SET=${2:-minimal}
    install_pkg_set packages.${PKG_SET}
    ;;
  test)
    # Do nothing, just sourcing
    set +o errexit
    ;;
  dconf)
    # Load dconf
    install_dconf
    ;;
  *)
    echo "Unknown operation $OPERATION." >/dev/stderr
    exit 1
    ;;
esac
