function dumpenv {
  tr '\0' '\n' < /proc/${1}/environ
}

if test -x "${HOME}/tools/starship/starship" ; then
  function starship_prompt {
    eval $($HOME/tools/starship/starship init zsh)
  }
fi
