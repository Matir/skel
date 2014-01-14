#!/bin/bash

set nounset
set errexit

BASEDIR=${BASEDIR:-$HOME/.dotfiles}

if [ ! -d $BASEDIR ] ; then
  echo "Please install to $BASEDIR!" &>2
  exit 1
fi

function install_dir {
  SRCDIR="${1}"
  find ${SRCDIR} \( -name .git -o \
                    -path ${SRCDIR}/private_dotfiles -o \
                    -name install.sh -o \
                    -name .gitignore \) \
      -prune -o -type f -print | \
    while read dotfile ; do
      TARGET="${HOME}/.${dotfile#${SRCDIR}/}"
      mkdir -p `dirname "${TARGET}"`
      ln -s -f "${dotfile}" "${TARGET}"
    done
}

install_dir "${BASEDIR}"
test -d "${BASEDIR}/private_dotfiles" && install_dir "${BASEDIR}/private_dotfiles"
