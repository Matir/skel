update_skel() {
  (cd $(dirname $(readlink $HOME/.profile)) &&
   cd $(git rev-parse --show-toplevel) &&
   git pull &&
   ./install.sh
  )
}
