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
