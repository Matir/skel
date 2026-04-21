# Find src-hilite-lesspipe.sh
_SRCHILITE=""
for _p in /usr/share/source-highlight/src-hilite-lesspipe.sh /opt/homebrew/bin/src-hilite-lesspipe.sh /usr/local/bin/src-hilite-lesspipe.sh ; do
  if [ -f "$_p" ] ; then
    _SRCHILITE="$_p"
    break
  fi
done

if [ -n "$_SRCHILITE" ] ; then
  function srcless {
    if [ $# -ne 1 ] ; then
      echo "Usage: srcless <file>" > /dev/stderr
      return 1
    fi
    "$_SRCHILITE" "$1" | less -R
  }
fi

unset _SRCHILITE _p
