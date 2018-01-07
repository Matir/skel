#!/bin/bash

# Update the weechat SSL key.  Should be called from cron via sudo.

eval WEEDIR="$(printf "~%q/.weechat/" "${SUDO_USER}")"
LIVEKEY="${WEEDIR}/ssl/relay.pem"

certbot renew -q
cat /etc/letsencrypt/live/$(hostname -f)/{privkey,fullchain}.pem > \
  ${LIVEKEY}
chown ${SUDO_USER}:$(id -gn ${SUDO_USER}) ${LIVEKEY}
for fifo in ${WEEDIR}/weechat_fifo* ; do
  echo '*/relay sslcertkey' > ${fifo}
done
