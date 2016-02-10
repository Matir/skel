function source_gnupg {
  GPG_ENV=${HOME}/.gnupg/gpg-agent.env
  if test -f ${GPG_ENV} ; then
    eval $(sed 's/^/export /' ${GPG_ENV})
  fi
}
