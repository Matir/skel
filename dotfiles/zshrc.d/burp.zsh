burp() {
  setopt localoptions nullglob
  local NO_DOWNLOAD
  local JAR
  if (( ${+argv[(r)*no-download]} )) ; then
    NO_DOWNLOAD=1
    shift
  else
    NO_DOWNLOAD=0
  fi
  JAR=(${HOME}/bin/burpsuite*jar(On[1])) 2>/dev/null
  if [ -z $JAR ] ; then
    if (( $NO_DOWNLOAD )) ; then
      echo "Not downloading, --no-download specified" >&2
      return 1
    fi
    echo "Burp JAR not found in ${HOME}/bin.  Attempting to download free edition." >&2
    wget -q --content-disposition --no-server-response -P ${HOME}/bin \
      https://portswigger.net/DownloadUpdate.ashx\?Product\=Free
    if [ $? -ne 0 ] ; then
      echo "Download failed." >&2
      return 1
    fi
    burp --no-download "$@"
    return $?
  else
    java -jar ${JAR} "$@"
  fi
}
