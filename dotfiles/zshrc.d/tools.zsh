if command -v rg &>/dev/null && test -e $HOME/.ripgreprc ; then
  export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
fi
