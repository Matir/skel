#!/bin/bash

set -ue

cat >/usr/local/bin/x-resize <<"EOF"
#!/bin/sh
PATH=/usr/bin:/bin:/usr/local/bin
desktopuser=$(/bin/ps -ef  | /bin/grep -oP '^\w+ (?=.*vdagent( |$))') || exit 0
export DISPLAY=:0
export XAUTHORITY=$(eval echo "~$desktopuser")/.Xauthority
/sbin/xrandr --output $(/sbin/xrandr | awk '/ connected/{print $1; exit; }') --auto
EOF

cat >/etc/udev/rules.d/50-resize.rules <<"EOF"
ACTION=="change",KERNEL=="card0", SUBSYSTEM=="drm", RUN+="/usr/local/bin/x-resize"
EOF
