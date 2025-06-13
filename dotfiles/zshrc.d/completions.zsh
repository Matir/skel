# Build some completions if they don't exist
# We run in the background to reduce shell startup time
{
  COMPDIR=${HOME}/.zshrc.completions
  function missing_comp() {
    test ! -f "$COMPDIR/$1"
  }

  have_command rustup && {
    missing_comp _rustup && rustup completions zsh > $COMPDIR/_rustup
    missing_comp _cargo && rustup completions zsh cargo > $COMPDIR/_cargo
  } || true

  have_command docker && \
    missing_comp _docker && \
    docker completion zsh > $COMPDIR/_docker || true
} &>/dev/null &!
