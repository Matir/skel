#!/bin/bash

set nounset
set errexit

BASEDIR=${BASEDIR:-$HOME/.dotfiles}

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

function install_dir {
  SRCDIR="${1}"
  find "${SRCDIR}" \( -name .git -o \
                    -path "${SRCDIR}/private_dotfiles" -o \
                    -name install.sh -o \
                    -name .gitignore \) \
      -prune -o -type f -print | \
    while read dotfile ; do
      TARGET="${HOME}/.${dotfile#${SRCDIR}/}"
      mkdir -p `dirname "${TARGET}"`
      ln -s -f "${dotfile}" "${TARGET}"
    done
}

function postinstall {
  # Install Vundle plugins
  if [ -d $HOME/.vim/bundle/Vundle.vim ] ; then
    vim +VundleInstall +qall
  fi
}

prerequisites
install_dir "${BASEDIR}"
test -d "${BASEDIR}/private_dotfiles" && install_dir "${BASEDIR}/private_dotfiles"
postinstall
