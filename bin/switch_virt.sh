#!/bin/bash

if [ $# -lt 1 ] ; then
  echo "Usage: $0 <kvm|vbox>" >&2
  exit 1
fi

if [ `whoami` != "root" ] ; then
  if which sudo >/dev/null 2>&1 ; then
    sudo "$0" "$@"
    exit
  fi
  echo "Sorry, this requires root." >&2
  exit 1
fi

if [ "$1" == "kvm" ] ; then
  /etc/init.d/virtualbox stop
  modprobe kvm
  modprobe kvm_intel
elif [ "$1" == "vbox" ]  ; then
  rmmod kvm_intel
  rmmod kvm
  /etc/init.d/virtualbox start
else
  echo 'WTF?' >&2
  exit 1
fi
