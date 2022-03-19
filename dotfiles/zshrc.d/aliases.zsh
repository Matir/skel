#!/usr/bin/env zsh

# On some systems, bat is batcat
if ! command -v bat >/dev/null 2>&1 ; then
  if command -v batcat >/dev/null 2>&1 ; then
    alias bat=$(command -v batcat)
  fi
fi
