function dmesg {
  if [ $(id -u) -eq 0 ] ; then
    command dmesg "$@"
  elif id | grep -q '(sudo)' ; then
    sudo dmesg "$@"
  else
    command dmesg "$@"
  fi
}
