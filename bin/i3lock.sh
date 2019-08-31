#!/bin/sh
LOCKER="i3lock -c 000000"
# intentionally want word splitting below
/usr/bin/xss-lock -- ${LOCKER} &
exec /usr/bin/xautolock \
  -time 5 \
  -detectsleep \
  -locker "${LOCKER}" \
  -notify 30 \
  -notifier "notify-send -u critical -t 10000 -- 'LOCKING SCREEN IN 30 SECONDS'"
