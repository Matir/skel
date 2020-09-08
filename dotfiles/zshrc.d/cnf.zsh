# TODO: this is horribly unportable.  Fix it.
if test -r /etc/zsh_command_not_found && test -r /var/lib/command-not-found/commands.db ; then
  source /etc/zsh_command_not_found
fi
