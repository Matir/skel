#!/usr/bin/env bash

set -o nounset
set -o errexit

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


function prerequisites {
  if which zsh > /dev/null 2>&1 ; then
    if [[ $- == *i* ]] ; then
      if [[ `getent passwd $USER | cut -d: -f7` != */zsh ]] ; then
        echo 'Enter password to change shell.' >&2
        chsh -s `which zsh`
      fi
    fi
    install_git https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
  else
    echo "ZSH not found!" >&2
  fi
  if which vim > /dev/null 2>&1 ; then
    mkdir -p $HOME/.vim/bundle
    install_git https://github.com/VundleVim/Vundle.vim.git \
      $HOME/.vim/bundle/Vundle.vim
  fi
}

function install_dotfile_dir {
  local SRCDIR="${1}"
  local dotfile
  find "${SRCDIR}" \( -name .git -o \
                    -path "${SRCDIR}/private_dotfiles" -o \
                    -name install.sh -o \
                    -name README.md -o \
                    -name .gitignore \) \
      -prune -o ${FINDTYPE} f -print | \
    while read dotfile ; do
      local TARGET="${HOME}/.${dotfile#${SRCDIR}/}"
      mkdir -p `dirname "${TARGET}"`
      ln -s -f "${dotfile}" "${TARGET}"
    done
}

function install_basic_dir {
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

function install_git {
  # Install or update a git repository
  if ! which git > /dev/null ; then
    return 1
  fi
  local REPO="${*: -2:1}"
  local DESTDIR="${*: -1:1}"
  set -- ${@:1:$(($#-2))}
  if [[ -d ${DESTDIR}/.git ]] ; then
    ( cd ${DESTDIR} ; git pull -q )
  else
    if [[ ${MINIMAL} -eq 1 ]] ; then
      git clone --depth 1 $* ${REPO} ${DESTDIR}
    else
      git clone $* ${REPO} ${DESTDIR}
    fi
  fi
}

function add_bin_symlink {
  local LINKNAME=${HOME}/bin/${2:-`basename $1`}
  if [[ -e ${LINKNAME} && ! -h ${LINKNAME} ]] ; then
    echo "Refusing to overwrite ${LINKNAME}" >&2
    return 1
  fi
  ln -sf ${1} ${LINKNAME}
}

# Custom version of pwndbg's installer
function install_pwndbg {
  if ! which gdb > /dev/null 2>&1 ; then
    return 1
  fi
  install_git -b stable https://github.com/pwndbg/pwndbg.git $HOME/.pwndbg
  mkdir -p $HOME/.pwndbg/vendor
  local PYVER=$(gdb -batch -q --nx -ex 'pi import platform; print(".".join(platform.python_version_tuple()[:2]))')
  local PYTHON=$(gdb -batch -q --nx -ex 'pi import sys; print(sys.executable)')
  PYTHON="${PYTHON}${PYVER}"
  local PY_PACKAGES=$HOME/.pwndbg/vendor
  ${PYTHON} -m pip install --target ${PY_PACKAGES} -Ur $HOME/.pwndbg/requirements.txt
  ${PYTHON} -m pip install --target ${PY_PACKAGES} -U capstone unicorn
  # capstone package is broken
  cp ${PY_PACKAGES}/usr/lib/*/dist-packages/capstone/libcapstone.so ${PY_PACKAGES}/capstone
}

function postinstall {
  # Install Vundle plugins
  if [[ -d $HOME/.vim/bundle/Vundle.vim ]] ; then
    vim +VundleInstall +qall
  fi
  # Install other useful tools
  install_git https://github.com/trustedsec/ptf.git ${HOME}/bin/ptframework && \
    add_bin_symlink ${HOME}/bin/ptframework/ptf
  # Refresh all gpg keys
  if test -x "`which gpg2`" ; then
    gpg2 --refresh-keys
  else
    gpg --refresh-keys
  fi
}

function ssh_key_already_installed {
  # Return 1 if the key isn't already installed, 0 if it is
  local AK="${HOME}/.ssh/authorized_keys"
  if [[ ! -f $AK ]] ; then
    return 1
  fi
  local KEYFP=`ssh-keygen -l -f $1 2>/dev/null | awk '{print $2}'`
  local TMPF=`mktemp`
  local key
  while read key ; do
    echo "$key" > $TMPF
    local EFP=`ssh-keygen -l -f ${TMPF} 2>/dev/null | awk '{print $2}'`
    if [[ "$EFP" == "$KEYFP" ]] ; then
      rm $TMPF 2>/dev/null
      return 0
    fi
  done < <(grep -v '^#' ${AK})
  rm $TMPF 2>/dev/null
  return 1
}

function install_ssh_keys {
  # Install SSH keys
  verbose 'Installing SSH keys...'
  local AK="${HOME}/.ssh/authorized_keys"
  local key
  local keydir
  if (( ${TRUST_ALL_KEYS} )) ; then
    keydir=${BASEDIR}/keys/ssh
  else
    keydir=${BASEDIR}/keys/ssh/trusted
  fi
  for key in ${keydir}/* ; do
    if [[ ! -f ${key} ]] ; then
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

function install_gpg_keys {
  local key
  for key in ${BASEDIR}/keys/gpg/* ; do
    gpg --import < ${key} >/dev/null
  done
}

function install_known_hosts {
  verbose 'Installing known hosts...' >&2
  if [[ ! -f ${BASEDIR}/keys/known_hosts ]] ; then
    return 0
  fi
  mkdir -p ${HOME}/.ssh
  if [[ -f ${HOME}/.ssh/known_hosts ]] ; then
    local tmpf=`mktemp`
    cat ${BASEDIR}/keys/known_hosts ${HOME}/.ssh/known_hosts | sort | uniq > $tmpf
    mv $tmpf ${HOME}/.ssh/known_hosts
  else
    cp ${BASEDIR}/keys/known_hosts ${HOME}/.ssh/known_hosts
  fi
}

function install_keys {
  install_ssh_keys
  install_gpg_keys
  install_known_hosts
}

function is_deb_system {
  test -f /usr/bin/apt-get
}

function run_as_root {
  # Attempt to run as root
  if [[ ${USER} == "root" ]] ; then
    "$@"
    return $?
  elif groups | grep -q '\bsudo\b' ; then
    verbose "Using sudo to run ${1}..."
    sudo "$@"
    return $?
  fi
  return 1
}

function install_pkg_set {
  local pkg_file=${BASEDIR}/${1}
  local pkg_list=""
  if [[ ! -f ${pkg_file} ]] ; then return 0 ; fi
  while read line ; do
    if [[ ${line:0:1} == '#' ]] ; then
      continue
    fi
    if [[ -z ${line} ]] ; then
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

function install_apt_pkgs {
  run_as_root apt-get update -qq || \
    ( echo "Can't run apt-get commands" >&2 && \
      return 1 )
  install_pkg_set packages.minimal
  if (( $MINIMAL )) ; then
    return 0
  fi
  (( $HAVE_X )) && install_pkg_set packages.X
  (( $IS_KALI )) && install_pkg_set packages.kali
  install_pkg_set packages.${ARCH}
  (( $HAVE_X )) && install_chrome
}

function install_chrome {
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

function read_saved_prefs {
  # Can't use basedir here as we don't have it yet
  local pref_file=`dirname $0`/installed-prefs
  if [ -f ${pref_file} ] ; then
    verbose "Loading saved skel preferences from ${pref_file}"
    source ${pref_file}
  fi
}

function save_prefs {
  (( $SAVE )) || return 0
  local pref_file=${BASEDIR}/installed-prefs
  (echo_pref BASEDIR
   echo_pref MINIMAL
   echo_pref INSTALL_KEYS
   echo_pref TRUST_ALL_KEYS
   echo_pref INSTALL_PKGS
   echo_pref VERBOSE) > $pref_file
}

function echo_pref {
  echo "$1=\${$1:-${!1}}"
}

function cleanup {
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

function verbose {
  (( ${VERBOSE:-0} )) && echo "$@" >&2 || return 0
}

# Operations

function install_main {
  (( $MINIMAL )) || prerequisites
  (( $INSTALL_PKGS )) && is_deb_system && install_apt_pkgs
  install_dotfile_dir "${BASEDIR}/dotfiles"
  test -d "${BASEDIR}/private_dotfiles" && \
    test -d "${BASEDIR}/.git/git-crypt" && \
    install_dotfile_dir "${BASEDIR}/private_dotfiles"
  test -d "${BASEDIR}/local_dotfiles" && \
    install_dotfile_dir "${BASEDIR}/local_dotfiles"
  install_basic_dir "${BASEDIR}/bin" "${HOME}/bin"
  (( $MINIMAL )) || postinstall
  (( $INSTALL_KEYS )) && install_keys
  save_prefs
  cleanup
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
if [[ ! -d $BASEDIR ]] ; then
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
  package*)
    if [ ${2:-default} != default ] ; then
      install_pkg_set packages.${2}
    else
      install_pkg_set packages
    fi
    ;;
  pwndbg)
    install_pwndbg
    ;;
  *)
    echo "Unknown operation $OPERATION." >/dev/stderr
    exit 1
    ;;
esac
