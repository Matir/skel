#!/bin/zsh

GCL=${HOME}/tools/gcloud

if [ -d "${GCL}" ] ; then
  # Add bin to path
  export PATH="${PATH}:${GCL}/bin"

  # Load completion
  source "${GCL}/completion.zsh.inc"
elif [ -f /usr/share/google-cloud-sdk/completion.zsh.inc ] ; then
  source /usr/share/google-cloud-sdk/completion.zsh.inc
elif [ -d /opt/homebrew/share/google-cloud-sdk/ ] ; then
  source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc
  source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
fi


which kubectl 2>/dev/null >&2 && \
  function kubectl() {
    if ! type __start_kubectl >/dev/null 2>&1; then
        source <(command kubectl completion zsh)
    fi

    command kubectl "$@"
  } || \
  true
