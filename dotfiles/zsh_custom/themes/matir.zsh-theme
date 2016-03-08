PROMPT='%{$fg[black]%}[%{$fg[yellow]%}%h%{$fg[black]%}] %{%(!.$fg[red].$fg[green])%}%8>..>%n%>>%{$fg[white]%}@%{$fg[blue]%}%12>..>%m%>>%{$fg[white]%}:%{$fg[green]%}%32<...<%~%<<%{$fg[magenta]%}$(virtualenv_prompt_info)%{$fg[blue]%}$(git_prompt_info)%{$fg[white]%}%#%{$reset_color%} '
ZSH_THEME_GIT_PROMPT_PREFIX=" ("
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_VIRTUALENV_PREFIX=" (py:"
ZSH_THEME_VIRTUALENV_SUFFIX=")"

# vim: set textwidth=0 wrapmargin=0
