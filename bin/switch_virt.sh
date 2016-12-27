#!/bin/sh

if [ "$1" -eq "kvm" ] ; then
  /etc/init.d/virtualbox stop
  modprobe kvm
  modprobe kvm_intel
elif [ "$1" -eq "vbox" ]  ; then
  rmmod kvm_intel
  rmmod kvm
  /etc/init.d/virtualbox start
else
  echo 'WTF?' >&2
fi
