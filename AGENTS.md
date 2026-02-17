## Installation and Environment

This is a set of dotfiles and utilities for setting up my personal environment
on POSIX-style environments. It is cloned from github and installed from the
`install.sh` script.

It mostly relies on symlinking dotfiles and other resources into the appropriate
locations, but also installs dependencies in various ways.

I primarily target Debian Linux-based (Debian, Ubuntu, and Kali Linux) systems
as well as MacOS.  Other platforms are lower priorities.  Shell scripts ending
in `.sh` should use only POSIX features unless there is a shebang line at the
beginning suggesting a different shell will be used.

`zsh` and `fish` are the key interactive shells to be configured, but `bash`
may also be used at times.

## Project Structure

*   `bin/`: Contains executable scripts that should be available in the shell's `PATH`.
*   `dotfiles/`: Contains configuration files (dotfiles) to be symlinked into the home directory.
*   `packages/`: Contains lists of packages to be installed by the `install.sh` script. Each file in this directory corresponds to a package set.
*   `install.sh`: The main installation script that sets up the environment, symlinks dotfiles, and installs packages.

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

### Adding a new dotfile

1.  Place the new dotfile in the `dotfiles/` directory.
2.  The `install.sh` script will automatically symlink it to the home directory.

### Adding a new script to `bin/`

1.  Add the new script to the `bin/` directory.
2.  Ensure the script is executable (`chmod +x`).

### Adding a new package

1.  Identify the appropriate package list in the `packages/` directory (e.g., `packages/cli`, `packages/kali`).
2.  Add the new package name to the list.
3.  If a new package set is required, create a new file in the `packages/` directory.

### Platform-specific changes

When making changes that are specific to a platform (e.g., Debian vs. macOS), please check for existing conventions in the `install.sh` script or other files. Use conditional logic (e.g., checking `uname`) to apply platform-specific settings.
