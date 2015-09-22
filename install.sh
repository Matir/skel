#!/bin/bash

set nounset
set errexit

BASEDIR=${BASEDIR:-$HOME/.skel}
MINIMAL=${MINIMAL:-0}
INSTALL_KEYS=${INSTALL_KEYS:-1}
INSTALL_PKGS=${INSTALL_PKGS:-$((1 - ${MINIMAL}))}

if [ ! -d $BASEDIR ] ; then
  echo "Please install to $BASEDIR!" 1>&2
  exit 1
fi

function prerequisites {
  # Prerequisites require git
  if ! which git > /dev/null ; then
    echo 'No git, not installing extras.' 1>&2
    return
  fi
  if which zsh > /dev/null ; then
    if [ `getent passwd $USER | cut -d: -f7` != `which zsh` ] ; then
      echo 'Enter password to change shell.' 1>&2
      chsh -s `which zsh`
    fi
    if [ ! -d $HOME/.oh-my-zsh ] ; then
      git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
    fi
  else
    echo "ZSH not found!" > /dev/stderr
  fi
  if which vim > /dev/null ; then
    mkdir -p $HOME/.vim/bundle
    if [ ! -d $HOME/.vim/bundle/Vundle.vim ] ; then
      git clone https://github.com/VundleVim/Vundle.vim.git \
        $HOME/.vim/bundle/Vundle.vim
    fi
  fi
}

function install_dotfile_dir {
  local SRCDIR="${1}"
  find "${SRCDIR}" \( -name .git -o \
                    -path "${SRCDIR}/private_dotfiles" -o \
                    -name install.sh -o \
                    -name README.md -o \
                    -name .gitignore \) \
      -prune -o -type f -print | \
    while read dotfile ; do
      local TARGET="${HOME}/.${dotfile#${SRCDIR}/}"
      mkdir -p `dirname "${TARGET}"`
      ln -s -f "${dotfile}" "${TARGET}"
    done
}

function install_basic_dir {
  local SRCDIR="${1}"
  local DESTDIR="${2}"
  find "${SRCDIR}" -type f -print | \
    while read file ; do
    local TARGET="${2}/${file#${SRCDIR}/}"
    mkdir -p `dirname "${TARGET}"`
    ln -s -f "${file}" "${TARGET}"
  done
}

function postinstall {
  # Install Vundle plugins
  if [ -d $HOME/.vim/bundle/Vundle.vim ] ; then
    vim +VundleInstall +qall
  fi
}

function ssh_key_already_installed {
  # Return 1 if the key isn't already installed, 0 if it is
  local AK="${HOME}/.ssh/authorized_keys"
  if [ ! -f $AK ] ; then
    return 1
  fi
  local KEYFP=`ssh-keygen -l -f $1 2>/dev/null | awk '{print $2}'`
  local TMPF=`mktemp`
  local key
  while read key ; do
    echo "$key" > $TMPF
    local EFP=`ssh-keygen -l -f ${TMPF} 2>/dev/null | awk '{print $2}'`
    if [ "$EFP" == "$KEYFP" ] ; then
      rm $TMPF 2>/dev/null
      return 0
    fi
  done < <(grep -v '^#' ${AK})
  rm $TMPF 2>/dev/null
  return 1
}

function install_ssh_keys {
  # Install SSH keys
  echo 'Installing SSH keys...' >&2
  local AK="${HOME}/.ssh/authorized_keys"
  local key
  for key in ${BASEDIR}/keys/ssh/* ; do
    if ssh_key_already_installed "${key}" ; then
      echo "Key `basename ${key}` already installed..." >&2
      continue
    fi
    echo "# `basename ${key}` added from skel on `date +%Y-%m-%d`" >> ${AK}
    cat ${key} >> ${AK}
  done
}

function install_gpg_keys {
  local key
  for key in ${BASEDIR}/keys/gpg/* ; do
    gpg --import < ${key}
  done
}

function install_known_hosts {
  echo 'Installing known hosts...' >&2
  if [ ! -f ${BASEDIR}/keys/known_hosts ] ; then
    return 0
  fi
  mkdir -p ${HOME}/.ssh
  if [ -f ${HOME}/.ssh/known_hosts ] ; then
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
  if [ ${USER} == "root" ] ; then
    "$@"
    return $?
  elif groups | grep -q '\bsudo\b' ; then
    echo "Using sudo to run ${1}..." >&2
    sudo "$@"
    return $?
  fi
  return 1
}

function install_apt_pkgs {
  run_as_root apt-get update || \
    echo "Can't run apt-get commands" >&2 && \
    return 1
  run_as_root apt-get -y install `cat ${BASEDIR}/packages`
}


(( $MINIMAL )) || prerequisites
(( $INSTALL_PKGS )) && is_deb_system && install_apt_pkgs
install_dotfile_dir "${BASEDIR}/dotfiles"
test -d "${BASEDIR}/private_dotfiles" && \
  install_dotfile_dir "${BASEDIR}/private_dotfiles"
install_basic_dir "${BASEDIR}/bin" "${HOME}/bin"
(( $MINIMAL )) || postinstall
(( $INSTALL_KEYS )) && install_keys
