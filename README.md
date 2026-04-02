### About ###

This is a repository of configuration files that I like to have on all the
machines that I use. For new systems, you can bootstrap by running the
included `clone.sh` script:

```bash
curl -L https://raw.githubusercontent.com/Matir/skel/master/clone.sh | bash
```

Alternatively, you can manually clone the repository and run `./install.sh`.

This started just as dotfiles, but expanded to include SSH keys, GPG keys,
and an ever-growing setup script.  There are various
options to install just parts of it, such as on a machine where I only have a
user account but no root.

This environment supports using `dotfile_overlays/` or `local_dotfiles/` to
manage machine-specific or private configurations. You can use
[git-crypt](https://github.com/AGWA/git-crypt) on these overlay directories
for things you don't want to splash all over the internet. :)
I still wouldn't check in anything terribly sensitive, like private keys.

### Usefulness ###

Mostly I post this to github so I can quickly grab the things I want, but it
might also be useful to others.  Feel free to raise an issue if you have any
questions.  I don't anticipating taking merge requests -- make your own
dotfiles.  ;)

### Options ###

### macOS-like Copy/Paste ###

To address keyboard shortcut conflicts between operating systems, this environment
now supports using `Alt+C` for copy and `Alt+V` for paste, similar to macOS.
This functionality is context-aware: it will automatically use `Ctrl+Shift+C/V`
in terminals and `Ctrl+C/V` in all other applications.

This feature requires the following packages to be installed:

-   `xbindkeys`: To listen for the keyboard shortcuts.
-   `xdotool`: To send the appropriate keypresses.

On Debian-based systems (like Ubuntu or Kali), you can install them with:

```bash
sudo apt-get update
sudo apt-get install xbindkeys xdotool
```

After installation, the functionality will be enabled automatically on your
next login.

On macOS, you can install the recommended packages using the included `Brewfile`:

```bash
brew bundle install
```

### Packages ###

The `packages/` directory contains lists of recommended packages. You can
manually install a set (e.g., on a Debian-based system) using:

```bash
grep -v "^#" packages/cli | xargs sudo apt-get install -y
```

```
BASEDIR: Where the skel framework is installed.  Defaults to $HOME/.skel
MINIMAL: Don't do things that require git clones or installation of anything
  not included in my .skel. (e.g., skips vim-plug, TPM) (Defaults to 0)
INSTALL_KEYS: Install GnuPG and SSH keys.  SSH keys are placed in
  authorized_keys. (Defaults to 1, installs keys.)
TRUST_ALL_KEYS: Allow all keys to be used for SSH login, versus a small subset.
VERBOSE: Enable verbose output during installation. (Defaults to 0)
SAVE: Save the install options to ${BASEDIR}/.installed-prefs
```

### TODO ###

-  [X] Re-do the installation of packages.
    -  [X] Make manual installation of sets easy/possible.
    -  [X] Make missing packages not cause a full set failure.
    -  [X] Allow comments and blank lines. in packages
