#!/bin/sh

export NAME=$(basename "$0")
export BASE="/opt/metasploit-framework" # TODO: search this path
unset GEM_PATH

if [ -f "${BASE}/bin/${NAME}" ] ; then
  exec "${BASE}/bin/${NAME}" "$@"
fi

if [ -f "${BASE}/embedded/framework/tools/exploit/${NAME}.rb" ]; then
  exec ${BASE}/embedded/bin/ruby \
    "${BASE}/embedded/framework/tools/exploit/${NAME}.rb" "$@"
fi

echo "Couldn't find script." >&2
exit 1
