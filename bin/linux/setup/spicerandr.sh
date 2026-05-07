#!/bin/bash

set -ue

cat >/usr/local/bin/x-resize <<"EOF"
#!/bin/sh
PATH=/usr/bin:/bin:/usr/local/bin
desktopuser=$(/bin/ps -ef  | /bin/grep -oP '^\w+ (?=.*vdagent( |$))') || exit 0
export DISPLAY=:0
export XAUTHORITY=$(eval echo "~$desktopuser")/.Xauthority
/usr/bin/xrandr --output $(/usr/bin/xrandr | awk '/ connected/{print $1; exit; }') --auto
EOF
chmod 755 /usr/local/bin/x-resize

cat >/etc/udev/rules.d/50-resize.rules <<"EOF"
ACTION=="change",KERNEL=="card0", SUBSYSTEM=="drm", RUN+="/usr/local/bin/x-resize"
EOF
chmod 644 /etc/udev/rules.d/50-resize.rules
