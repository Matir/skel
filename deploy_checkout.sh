#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") [--dry-run] user@host" >&2
  exit 1
}

DRY_RUN=0
REMOTE=

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage
      ;;
    *)
      if [[ -n "${REMOTE}" ]]; then
        usage
      fi
      REMOTE="$1"
      shift
      ;;
  esac
done

if [[ $# -gt 0 || -z "${REMOTE}" ]]; then
  usage
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if ! git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: $SCRIPT_DIR is not inside a git repository." >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  archive_list="$(git -C "$SCRIPT_DIR" archive --format=tar HEAD | tar -tf - | sed 's#^\./##' | sed '/^$/d;/^\.$/d' | sort)"
  remote_list="$(ssh "$REMOTE" 'if [ -d "$HOME/.skel" ]; then cd "$HOME/.skel" && find . | sed "s#^\./##" | sed "/^$/d;/^\.$/d" | sort; fi' || true)"

  printf 'Would deploy HEAD from %s to %s:%s\n' "$SCRIPT_DIR" "$REMOTE" '$HOME/.skel'
  printf 'Would replace remote ~/.skel with %s tracked paths\n' "$(printf '%s' "$archive_list" | awk 'NF { n++ } END { print n + 0 }')"
  if [[ -n "$remote_list" ]]; then
    printf 'Would remove %s existing remote paths not present in HEAD\n' "$(comm -13 <(printf '%s\n' "$archive_list") <(printf '%s\n' "$remote_list") | awk 'NF { n++ } END { print n + 0 }')"
  else
    printf 'Remote ~/.skel does not exist or is empty\n'
  fi
  exit 0
fi

git -C "$SCRIPT_DIR" archive --format=tar HEAD | \
  ssh "$REMOTE" 'rm -rf "$HOME/.skel" && mkdir -p "$HOME/.skel" && tar -xf - -C "$HOME/.skel"'
