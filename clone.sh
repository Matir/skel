#!/bin/bash

set -ue

# Script to clone and install

# Wrapped in a function to prevent incomplete execution if download is
# interrupted
function installer_main {
  if ! command -v git >/dev/null 2>&1 ; then
    ( if [ "$EUID" != 0 ] ; then
      sudo apt install -y git
    else
      apt install -y git
      fi ) || ( echo 'Failed to install git!' >/dev/stderr; false)
  fi

  git clone --depth 1 https://github.com/Matir/skel.git ${HOME}/.skel

  ${HOME}/.skel/install.sh
}

installer_main
