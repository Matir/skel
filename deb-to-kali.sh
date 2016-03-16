#!/bin/bash

if [ `whoami` != "root" ] ; then
  echo "This must be run as root." >&2
  exit 1
fi

BASEDIR=`dirname $0`
if ! -f ${BASEDIR}/keys/gpg/kali-repo.key ; then
  echo "Couldn't find key, are you in the right place?" >&2
  exit 1
fi

cat >/etc/apt/sources.list.d/kali.list <<KALI_EOF
deb http://http.kali.org/kali kali-rolling main contrib non-free
KALI_EOF

/usr/bin/apt-key add ${BASEDIR}/keys/gpg/kali-repo.key
/usr/bin/apt-get update
/usr/bin/apt-get install -y kali-linux-full
