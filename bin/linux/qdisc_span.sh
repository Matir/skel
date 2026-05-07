#!/bin/bash

set -ue

ACTION="add"

if [ "${1}" == "-d" ] ; then
  ACTION="del"
  shift
fi

BRIDGE="${1}"
DEST="${2}"

function setup_span {
  if tc qdisc show dev "${1}" | grep -q 'qdisc ingress ffff' ; then
    return 0
  fi
  tc qdisc add dev "${1}" ingress
  tc filter add dev "${1}" parent ffff: protocol all u32 match u8 0 0 action mirred egress mirror dev "${DEST}"
}

function del_span {
  tc qdisc del dev "${1}" ingress
}

function handle_iface {
  case "${ACTION}" in
    add)
      setup_span "${1}"
      ;;
    del)
      del_span "${1}"
      ;;
    *)
      echo "Unknown action!"
      exit 1
      ;;
  esac
}

function get_bridge_ifaces {
  bridge link | grep "master ${1}" | cut -d: -f2 | cut -d@ -f1
}

get_bridge_ifaces "${BRIDGE}" | while IFS= read -r iface ; do
  handle_iface "$iface"
done
