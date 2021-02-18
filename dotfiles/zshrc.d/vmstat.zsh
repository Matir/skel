function vmstat {
  local _extra_args
  if [ "$(tput cols)" -gt 80 ] ; then
    _extra_args="-w"
  fi
  command vmstat ${_extra_args} "$@"
}
