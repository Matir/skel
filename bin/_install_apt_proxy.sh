#!/bin/bash

set -o errexit
set -o nounset

if test -f /etc/apt/apt.conf.d/90-proxy ; then
  echo "Looks already setup."
fi

cat >/etc/apt/proxy-detect <<'EOF'
#!/bin/bash

PROXY=192.168.60.10:3142

if ! test -x /bin/nc ; then
  echo DIRECT
  exit 0
fi

if nc -w 2 -z ${PROXY/:/ } ; then
  echo ${PROXY}
  exit 0
fi

echo DIRECT
EOF

chmod +x /etc/apt/proxy-detect

cat >/etc/apt/apt.conf.d/90-proxy <<'EOF'
Acquire::http::Proxy-Auto-Detect "/etc/apt/proxy-detect";
EOF

echo "Setup APT Proxying."
