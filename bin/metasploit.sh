#!/bin/sh

export NAME=$(basename "$0")
export BASE="/opt/metasploit" # TODO: search this path

# Autogen'd
. ${BASE}/scripts/setenv.sh

# Use Pro's bundled gems instead of the gemcache
export MSF_BUNDLE_GEMS=0
export BUNDLE_GEMFILE=${BASE}/apps/pro/Gemfile

# Set a flag so Gemfile can limit gems
export FRAMEWORK_FLAG=true

export MSF_DATABASE_CONFIG=${BASE}/apps/pro/ui/config/database.yml
export TERMINFO=${BASE}/common/share/terminfo/

# Check for ruby scripts such as msfconsole directly to avoid having to add
# msf3 to the path.
if [ -f "${BASE}/apps/pro/msf3/${NAME}" ]; then
	exec ${BASE}/apps/pro/msf3/${NAME} "$@"
fi
if [ -f "${BASE}/apps/pro/msf3/tools/exploit/${NAME}.rb" ]; then
  exec ${BASE}/apps/pro/msf3/tools/exploit/${NAME}.rb "$@"
fi

# Can cause recursive loop
# exec ${NAME} "$@"
