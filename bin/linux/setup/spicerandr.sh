#!/bin/bash

set -ue

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root." >&2
  exit 1
fi

cat >/usr/local/bin/x-resize <<"EOF"
#!/bin/sh
PATH=/usr/bin:/bin:/usr/local/bin
desktopuser=$(/bin/ps -eo user,comm 2>/dev/null | awk '$2 ~ /vdagent/ {print $1; exit}')
[ -z "$desktopuser" ] && exit 0
desktophome=$(getent passwd "$desktopuser" | cut -d: -f6)
[ -z "$desktophome" ] && exit 0
export DISPLAY=:0
export XAUTHORITY="${desktophome}/.Xauthority"
/usr/bin/xrandr --output $(/usr/bin/xrandr | awk '/ connected/{print $1; exit; }') --auto
EOF
chmod 755 /usr/local/bin/x-resize

cat >/etc/udev/rules.d/50-resize.rules <<"EOF"
ACTION=="change",KERNEL=="card0", SUBSYSTEM=="drm", RUN+="/usr/local/bin/x-resize"
EOF
chmod 644 /etc/udev/rules.d/50-resize.rules
