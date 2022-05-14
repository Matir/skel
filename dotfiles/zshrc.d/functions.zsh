function dumpenv {
  tr '\0' '\n' < /proc/${1}/environ
}

if test -x "/sbin/starship" ; then
  function starship_prompt {
    eval $(/sbin/starship init zsh)
  }
elif test -x "${HOME}/tools/starship/starship" ; then
  function starship_prompt {
    eval $($HOME/tools/starship/starship init zsh)
  }
fi
