# Enable RVM if available
if [[ -s ${HOME}/.rvm/scripts/rvm ]] ; then
  source ${HOME}/.rvm/scripts/rvm
else
  function install_rvm {
    export rvm_ignore_dotfiles=yes
    pushd `mktemp -d`
    curl -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer
    curl -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer.asc
    gpg --verify rvm-installer.asc && \
      bash rvm-installer stable
    popd
  }
fi
