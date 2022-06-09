function dumpenv {
  tr '\0' '\n' < /proc/${1}/environ
}

if test -x "/sbin/starship" ; then
  _STARSHIP_PATH="/sbin/starship"
  function starship_prompt {
    eval $(/sbin/starship init zsh)
  }
elif test -x "${HOME}/tools/starship/starship" ; then
  _STARSHIP_PATH="${HOME}/tools/starship/starship"
  function starship_prompt {
    eval $($HOME/tools/starship/starship init zsh)
  }
fi
if test -f ${HOME}/.zprompt ; then
  if test "$(cat ${HOME}/.zprompt)" = "starship" ; then
    if test -n "${_STARSHIP_PATH:-}" ; then
      eval $(${_STARSHIP_PATH} init zsh)
    fi
  fi
fi
unset _STARSHIP_PATH
