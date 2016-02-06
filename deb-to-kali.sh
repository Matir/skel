#!/bin/bash

if [ `whoami` != "root" ] ; then
  echo "This must be run as root." >&2
  exit 1
fi

BASEDIR=`dirname $0`

cat >/etc/apt/sources.list.d/kali.list <<KALI_EOF
deb http://http.kali.org/kali kali-rolling main contrib non-free
KALI_EOF

/usr/bin/apt-key add ${BASEDIR}/kali-repo.key
/usr/bin/apt-get update
/usr/bin/apt-get install -y kali-linux-full
