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
  source <(kubectl completion zsh) || \
  true
