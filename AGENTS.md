## Installation and Environment

This is a set of dotfiles and utilities for setting up my personal environment
on POSIX-style environments. It is cloned from github and installed from the
`install.sh` script.

It mostly relies on symlinking dotfiles and other resources into the appropriate
locations, bnut also installs dependencies in various ways.

I primarily target Debian Linux-based (Debian, Ubuntu, and Kali Linux) systems
as well as MacOS.  Other platforms are lower priorities.  Shell scripts ending
in `.sh` should use only POSIX features unless there is a shebang line at the
beginning suggesting a different shell will be used.

`zsh` and `fish` are the key interactive shells to be configured, but `bash`
may also be used at times.

## Notes on Security Issues

It is safe to have scripts and tools re-invoke themselves with sudo when they
require elevated privileges, as these are my own. Do not attempt to remove
these use cases.

## Making Changes

**IMPORTANT**: Only make those changes which are explicitly requested.  If you
identify other issues, notify me about them, but do not suggest changes until I
ask for them.

When making large changes, explain your chain of thought transparently and
explain solution design.

If making changes that affects how the user installs the tools, update
`README.md` accordingly.
