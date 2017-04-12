#!/bin/sh
exec /usr/bin/xautolock \
  -time 5 \
  -locker "i3lock -c 000000" \
  -notify 30 \
  -notifier "notify-send -u critical -t 10000 -- 'LOCKING SCREEN IN 30 SECONDS'"
