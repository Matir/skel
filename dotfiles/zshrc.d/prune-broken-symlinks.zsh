prune-broken-symlinks() {
  setopt localoptions nounset
  local ASK
  local DIR
  local FINDCMD
  local i

  if [[ "${1:-}" == "-y" ]] ; then
    ASK=0
    shift
  else
    ASK=1
  fi
  DIR=${1:-.}
  FINDCMD=(find -L ${DIR} -xdev -type l)
  if (($ASK)) ; then
    local FILES
    FILES=`${FINDCMD} -print`
    if [[ "${FILES}" == "" ]] ; then
      return 0
    fi
    echo ${FILES}
    echo -n 'Delete these links? [y/n] '
    if read -q ; then
      ${FINDCMD} -delete
    fi
    echo
  else
      ${FINDCMD} -print -delete
  fi
}
