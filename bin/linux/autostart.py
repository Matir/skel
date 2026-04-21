#!/usr/bin/python
"""
Launch desktop files from ~/.config/autostart
"""

import glob
import os.path
from gi.repository import Gio

dirname = os.path.expanduser('~/.config/autostart')
for desktop in glob.glob(os.path.join(dirname, '*.desktop')):
    try:
        fp = Gio.DesktopAppInfo.new_from_filename(desktop)
    except TypeError:
        continue
    fp.launch_uris([], None)
