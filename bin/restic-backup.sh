#!/bin/bash

set -ue

export RESTIC_DEFAULT_BE="google"
export RESTIC_PASSWORD_FILE=${HOME}/.restic-password

case "${RESTIC_BACKEND:=${RESTIC_DEFAULT_BE}}" in
  google)
    export GOOGLE_PROJECT_ID=systemoverlord.com:systemoverlord
    export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/.config/boto/restic-creds.json
    export RESTIC_REPOSITORY="gs:systemoverlord-backups-scar-2:/"
    ;;
  b2)
    . ${HOME}/.restic-backups-scar-creds
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    export RESTIC_REPOSITORY="s3:s3.us-west-004.backblazeb2.com/systemoverlord-backups-scar"
    ;;
  *)
    echo "Unknown restic backend $RESTIC_BACKEND" >&2
    exit 1
    ;;
esac

cd ${HOME}

if [ -z "${1}" ] ; then

  restic backup \
    --files-from "${HOME}/.restic-backup" \
    --limit-upload 5000 \
    --limit-download 10000

else
  restic "$@"
fi
