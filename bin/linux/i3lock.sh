#!/bin/sh
LOCKTIME="${SCREENSAVER_MIN:-5}"
LOCKER="i3lock -c 000000"
# Cleanup previously leaked background agents
pkill -x xss-lock 2>/dev/null || true
pkill -x xautolock 2>/dev/null || true

# intentionally want word splitting below
# do not quote this
/usr/bin/xss-lock -- ${LOCKER} &
exec /usr/bin/xautolock \
  -time "${LOCKTIME}" \
  -detectsleep \
  -locker "${LOCKER}" \
  -notify 30 \
  -notifier "notify-send -u critical -t 10000 -- 'LOCKING SCREEN IN 30 SECONDS'"
