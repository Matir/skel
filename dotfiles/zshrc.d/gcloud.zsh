#!/bin/zsh

GCL=${HOME}/tools/gcloud

if [ ! -d ${GCL} ] ; then
  return
fi

# Add bin to path
export PATH="${PATH}:${GCL}/bin"

# Load completion
source ${GCL}/completion.zsh.inc

which kubectl 2>/dev/null >&2 && \
  function kubectl() {
    if ! type __start_kubectl >/dev/null 2>&1; then
        source <(command kubectl completion zsh)
    fi

    command kubectl "$@"
  } || \
  true
