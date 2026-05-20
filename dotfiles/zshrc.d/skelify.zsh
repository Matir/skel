#!/bin/zsh
#
# Skelify -- move a file to my .skel and setup symlinks

function skelify {
  local -A opts
  zparseopts -D -A opts -overlay:

  local overlay_name="${opts[--overlay]}"
  local base_skel_dir="${HOME}/.skel/dotfiles"
  local extra_args=()
  if [[ -n "${overlay_name}" ]]; then
    base_skel_dir="${HOME}/.skel/dotfile_overlays/${overlay_name}"
    extra_args=(--overlay "${overlay_name}")
  fi

  local target
  local whichdir
  local relhome
  local fname
  local fulltarget
  for target in $~@; do
    if test -d ${target} ; then
      skelify "${extra_args[@]}" ${target}/* || return 1
    elif test -f ${target} ; then
      if ! whichdir=$(cd $(dirname $target) && pwd); then
        echo Could not find directory for $target >/dev/stderr
        return 1
      fi
      fname=$(basename ${target})
      fulltarget="${whichdir}/${fname}"
      if [[ ${whichdir} == ${HOME} ]] ; then
        relhome=""
      elif [[ ${whichdir} == ${HOME}/* ]] ; then
        relhome=${whichdir#${HOME}/}
      else
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
      local skeldir="${base_skel_dir}/${relhome}"
      mkdir -p "${skeldir}"
      mv ${target} "${skeldir}/${fname}"
      ln -s "${skeldir}/${fname}" "${fulltarget}"
    else
      echo ${target} is not a directory or file. >/dev/stderr
      return 1
    fi
  done
}
