#!/usr/bin/env zsh

# On some systems, bat is batcat
if ! command -v bat >/dev/null 2>&1 ; then
  if command -v batcat >/dev/null 2>&1 ; then
    alias bat=$(command -v batcat)
  fi
fi

# FFUF aliases
if command -v ffuf >/dev/null 2>&1 ; then
  if test -d $HOME/tools/seclists ; then
    alias ffuf-files="ffuf -c -w $HOME/tools/seclists/Discovery/Web-Content/raft-large-files.txt"
    alias ffuf-dirs="ffuf -c -w $HOME/tools/seclists/Discovery/Web-Content/raft-large-directories.txt"
    alias ffuf-quick="ffuf -c -w $HOME/tools/seclists/Discovery/Web-Content/quickhits.txt"
  fi
fi

if grep --help 2>/dev/null | grep -q 'color'; then
  # Should have a better way to check for GNU versions
  alias grep='grep --color=auto'
  alias egrep='egrep --color=auto'
  alias fgrep='fgrep --color=auto'
fi

# Detect which `ls` flavor is in use and use the right flag for colors.
if ls --help 2>&1 | grep -q -- '--color'; then
  alias ls='ls --color=auto' # GNU `ls`
elif [ "$(uname)" = "Darwin" ]; then
  alias ls='ls -G' # macOS `ls`
fi
