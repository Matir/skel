prune-broken-symlinks() {
  setopt localoptions nounset
  find $1 -type l -xtype l -print -delete
}
