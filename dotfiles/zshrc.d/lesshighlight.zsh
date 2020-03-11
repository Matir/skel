test -f /usr/share/source-highlight/src-hilite-lesspipe.sh && \
  function srcless {
    if [ $# -ne 1 ] ; then
      echo "$0 <what>" > /dev/stderr
      return 1
    fi
    /usr/share/source-highlight/src-hilite-lesspipe.sh $1 | less -R
  }
