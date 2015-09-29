function afk {
  # Note, may fail if multiple users are logged in with different desktop
  # environments.
  if pidof cinnamon-screensaver >/dev/null ; then
    cinnamon-screensaver-command -l
  elif pidof gnome-screensaver >/dev/null ; then
    gnome-screensaver-command -l
  else
    echo 'No screensaver found...' >&2
  fi
}
