#!/bin/bash

set -o nounset
set -o errexit

if [ "$(uname)" != "Linux" ]; then
  echo "Error: This backup script is only intended for use on Linux." >&2
  exit 1
fi

shopt -s nullglob
matches=( /media/"${USER}"/[bB]ackup/"${USER}"/ )
shopt -u nullglob
if [ ${#matches[@]} -gt 0 ]; then
  DEFAULT="${matches[0]}"
else
  DEFAULT="/media/${USER}/Backup/${USER}/"
fi
DEST="${1:-${DEFAULT}}"

function verify_dest {
  if [ -z "$1" ] ; then
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
    read -r
  fi
}

verify_dest "$DEST"

time nice rsync -Hax --delete --exclude-from="$HOME/.rsync_ignore" \
  --delete-excluded "${HOME}/" "$DEST"
echo "Backup completed..."
time sync
echo "Run finished, safe to unmount."
