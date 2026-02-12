#!/usr/bin/env bash

set -ueo pipefail
shopt -s extglob

# get libraries
. ${HOME}/.local/lib/bash/tui.sh

COMMANDS=(
  gctx
  kctx
)

_make_extglob() {
  local IFS='|'
  echo "@($*)"
}

CMD_PATTERN=$(_make_extglob "${COMMANDS[@]}")

usage() {
  echo "Available Subcommands:"
  printf "  - %-10s\n" "${COMMANDS[@]}"
  exit 1
}

_gctx_set() {
  gcloud config configurations activate "${1}" </dev/null
}

_gctx_choose() {
  local lines=()
  local default=''
  local maxnamelen=0
  local active name description
  while IFS=$'\t' read -r active name description ; do
    (( maxnamelen = ( ${#name} > maxnamelen ) ? ${#name} : maxnamelen ))
    if [[ "$active" == "True" ]] ; then
      default="${name}"
    fi
    lines+=("${name}" "${description}")
  done < <(gcloud config configurations list \
    --format='value(is_active, name, format("{} (as {})", properties.core.project, properties.core.account))')
  local choice
  if choice=$(printf "%-${maxnamelen}s %s\n" "${lines[@]}" | select_entry "gcloud config" "$default") ; then
    _gctx_set "${choice}"
  else
    echo "No option selected, leaving unchanged."
  fi
  return 0
}

_gctx_new() {
  local cname="${1:-}"
  if test -z "${cname}" ; then
    echo "Usage: gctx new <new name>" >&2
    return 1
  fi
  gcloud config configurations create "${cname}"
}

_gctx_name() {
  gcloud info --format='value(config.active_config_name)'
}

_gctx_clone() {
  # save old config
  local oldconfig=()
  local line
  while IFS= read -r line ; do
    old_config+=("$line")
  done < <(gcloud config configurations describe "$(_gctx_name)" --format='multi(properties:format="flattened[separator=\" \"]")')

  # create new
  _gctx_new "${1:-}"

  # set config
  for line in "${oldconfig[@]}" ; do
    local keyname="${line%% *}"
    local keypath="${keyname//\.//}"
    local value="${line#* }"
    gcloud config set "${keypath}" "${value}"
  done
  return 0
}

gctx() {
  local subcmd="${1:-}"
  shift || true
  case "${subcmd}" in
    clone)
      _gctx_clone "$@"
      return
      ;;
    new)
      _gctx_new "$@"
      return
      ;;
    show)
      gcloud config configurations list --filter="is_active=True" \
        --format='table(name, properties.core.account, properties.core.project, properties.compute.zone:label=COMPUTE_DEFAULT_ZONE, properties.compute.region:label=COMPUTE_DEFAULT_REGION)' \
        "$@"
      ;;
    list)
      gcloud config configurations list "$@"
      return
      ;;
    activate)
      _gctx_set "$@"
      return
      ;;
    ""|choose)
      _gctx_choose
      return
      ;;
    *)
      if _gctx_set "${subcmd}" 2>/dev/null ; then
        return 0
      fi
      echo "Usage: gctx [show|list|new|choose|clone|<name>]" >&2
      return 1
      ;;
  esac
}

kctx() {
  return 0
}

INVOKED_AS=$(basename "$0")
# shellcheck disable=SC2053
if [[ "$INVOKED_AS" == $CMD_PATTERN ]] ; then
  CMD="${INVOKED_AS}"
else
  CMD="${1:-}"
  shift || usage
fi


# shellcheck disable=SC2254
case "${CMD}" in
  ${CMD_PATTERN})
    "${CMD}" "$@"
    ;;
  *)
    usage
    ;;
esac
