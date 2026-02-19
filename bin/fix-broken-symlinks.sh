#!/bin/bash

# A script to find and remove broken symbolic links in a directory.
#
# OPTIONS:
#   -y: Automatically remove all broken links without confirmation.
#   -q: Quiet mode. Suppress all non-error output.

set -euo pipefail

# --- Default settings ---
FORCE_DELETE=0
QUIET=0
TARGET_DIR="."

# --- Helper function for logging ---
log() {
  if [ "${QUIET}" -eq 0 ]; then
    echo "$@"
  fi
}

# --- Usage function ---
usage() {
  echo "Usage: $0 [-y] [-q] [TARGET_DIRECTORY]"
  echo "  -y: Yes. Automatically remove broken symlinks without confirmation."
  echo "  -q: Quiet. Suppress all output except for errors."
  echo "  TARGET_DIRECTORY: The directory to scan. Defaults to the current directory."
  exit 1
}

# --- Parse command-line options ---
while getopts "yq" opt; do
  case ${opt} in
    y)
      FORCE_DELETE=1
      ;;
    q)
      QUIET=1
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND - 1)) # Remove the parsed options

# --- Set target directory ---
# Use the first remaining argument as the target directory.
if [ -n "$1" ]; then
  TARGET_DIR="$1"
fi

if [ ! -d "${TARGET_DIR}" ]; then
  echo "Error: Directory '${TARGET_DIR}' not found." >&2
  exit 1
fi

log "Searching for broken symlinks in '${TARGET_DIR}'..."

# --- Main logic ---
# Find broken symlinks and process them.
find "${TARGET_DIR}" -type l ! -exec test -e {} \; -print0 | while IFS= read -r -d '' link; do
  if [ "${FORCE_DELETE}" -eq 1 ]; then
    # No confirmation needed, just delete.
    if rm "${link}"; then
      log "Removed '${link}'."
    else
      # Errors should still be reported.
      echo "Failed to remove '${link}'." >&2
    fi
  else
    # If in quiet mode but not force mode, we can't prompt, so we skip.
    if [ "${QUIET}" -eq 1 ]; then
        continue
    fi
    # Ask the user for confirmation.
    read -p "Remove broken symlink '${link}'? [y/N] " -n 1 -r
    echo # Move to a new line after input.

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if rm "${link}"; then
        log "Removed '${link}'."
      else
        echo "Failed to remove '${link}'." >&2
      fi
    else
      log "Skipped '${link}'."
    fi
  fi
done

log "Cleanup complete."