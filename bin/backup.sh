#!/bin/bash

set -o nounset
set -o errexit

DEFAULT=`echo /media/${USER}/[bB]ackup/${USER}/`
DEST="${1:-${DEFAULT}}"

function verify_dest {
  arr=($1)
  items=${#arr[@]}
  if [ $items -ne 1 ] ; then
    echo "Bad count of backup destinations." > /dev/stderr
    exit 1
  fi
  dir="$1"
  end=$((${#dir}-1))
  last="${dir:$end:1}"
  if [ "$last" != "/" ] ; then
    echo -n "Destination $dir does not end in a /, " > /dev/stderr
    echo "this is probably not what you want!" > /dev/stderr
    echo "Press a key to continue, or CTRL-C to cancel." > /dev/stderr
    read
  fi
}

verify_dest "$DEST"

exec nice rsync -Hax --delete --exclude-from="$HOME/.rsync_ignore" \
  --delete-excluded "${HOME}/" "$DEST"
