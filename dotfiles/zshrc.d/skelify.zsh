#!/bin/zsh
#
# Skelify -- move a file to my .skel and setup symlinks

function skelify {
  local target
  local whichdir
  local relhome
  local fname
  local fulltarget
  for target in $~@; do
    if test -d ${target} ; then
      skelify ${target}/* || return 1
    elif test -f ${target} ; then
      if ! whichdir=$(cd $(dirname $target) && pwd); then
        echo Could not find directory for $target >/dev/stderr
        return 1
      fi
      fname=$(basename ${target})
      relhome=${whichdir#${HOME}/}
      fulltarget="${whichdir}/${fname}"
      if [[ ${relhome} == ${whichdir} ]] ; then
        echo ${whichdir} is not in home >/dev/stderr
        return 1
      fi
      if [[ ${relhome:0:1} == "." ]] ; then
        relhome=${relhome:1}
      elif [[ ${fname:0:1} == "." ]] ; then
        fname=${fname:1}
      else
        echo skelify only supports dotfiles >/dev/stderr
        return 1
      fi
      echo ${target}
      local skeldir="${HOME}/.skel/dotfiles/${relhome}"
      mkdir -p "${skeldir}"
      mv ${target} "${skeldir}/${fname}"
      ln -s "${skeldir}/${fname}" "${fulltarget}"
    else
      echo ${target} is not a directory or file. >/dev/stderr
      return 1
    fi
  done
}
