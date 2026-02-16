#!/bin/bash
#
# Script to execute a restic backup script specific to the current hostname.
#
set -o errexit
set -o nounset
set -o pipefail

# Get the current hostname
HOSTNAME=$(hostname)

# Define the directory where hostname-specific scripts are stored
RESTIC_SCRIPTS_DIR="${HOME}/bin/restic"

# Construct the full path to the hostname-specific script
HOST_SPECIFIC_SCRIPT="${RESTIC_SCRIPTS_DIR}/${HOSTNAME}"

# Check if the script exists and is executable
if [[ -f "${HOST_SPECIFIC_SCRIPT}" && -x "${HOST_SPECIFIC_SCRIPT}" ]]; then
  echo "Executing restic script for hostname: ${HOSTNAME}"
  "${HOST_SPECIFIC_SCRIPT}"
else
  echo "Error: No executable restic script found for hostname '${HOSTNAME}' at '${HOST_SPECIFIC_SCRIPT}'." >&2
  echo "Please create an executable script at that path if you want to use this functionality." >&2
  exit 1
fi
