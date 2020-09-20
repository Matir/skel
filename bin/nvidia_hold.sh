#!/bin/bash

function list_nvidia_installed {
  dpkg-query -l '*nvidia*' | grep '^[hi]i' | awk '{print $2}'
}

function hold_or_unhold {
  apt-mark "${1:-hold}" $(list_nvidia_installed)
}

case "$1" in
  hold|h)
    hold_or_unhold hold
    ;;
  unhold|u)
    hold_or_unhold unhold
    ;;
  *)
    echo "$0 <hold|unhold>" >/dev/stderr
    exit 1
    ;;
esac
