function dmesg {
  if [ $(id -u) -eq 0 ] ; then
    command dmesg "$@"
  elif sudo -n true 2>/dev/null ; then
    sudo dmesg "$@"
  else
    command dmesg "$@"
  fi
}
