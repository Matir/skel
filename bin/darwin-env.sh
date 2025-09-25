#!/bin/sh

env > ${TMPDIR}/env-pre
. ${HOME}/.shenv
env > ${TMPDIR}/env-post
for VAR in $(env | cut -d'=' -f1) ; do
  /bin/launchctl setenv "${VAR}" "$(eval echo \$${VAR})"
done
