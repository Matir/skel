if command -v mise ; then
  use_mise() {
    eval "$(mise direnv activate)"
  }
fi
