
### About ###
This is a repository of configuration files that I like to have on all the
machines that I use.  I can just clone the repository and run "repo/setup.sh"
and get most things setup the way I like them.

This started just as dotfiles, but expanded to include SSH keys, GPG keys,
packages I like installed, and an ever-growing setup script.  There are various
options to install just parts of it, such as on a machine where I only have a
user account but no root.

### Usefulness ###
Mostly I post this to github so I can quickly grab the things I want, but it
might also be useful to others.  Feel free to raise an issue if you have any
questions.  I don't anticipating taking merge requests -- make your own
dotfiles.  ;)

### Options ###
```
BASEDIR: Where the skel framework is installed.  Defaults to $HOME/.skel
MINIMAL: Don't do things that require git clones or installation of anything
  not included in my .skel.  (Defaults to 0, installs everything.)
INSTALL_KEYS: Install GnuPG and SSH keys.  SSH keys are placed in
  authorized_keys. (Defaults to 1, installs keys.)
INSTALL_PKGS: Install common packages, if on a Debian-like system.
  (Defaults to opposite of $MINIMAL.)
```
