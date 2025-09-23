#!/bin/bash

# Screenshot tool to try a few different tools

set -ue

TOOLS="flameshot scrot"
SCREENDIR=${SCREENDIR:-${HOME}/Pictures/Screenshots}
SCROT_FORMAT="%F-%T.png"

function default_screenshot_command {
  for tool in ${TOOLS} ; do
    if which "${tool}" >/dev/null 2>&1 ; then
      echo "${tool}"
      return 0
    fi
  done
  exit 1
}

TOOL=${SHOT:-$(default_screenshot_command)}
CMD=${1:-region}

function flameshot_gui_capture {
  flameshot gui -p "${SCREENDIR}"
}

function flameshot_full_capture {
  flameshot full -p "${SCREENDIR}"
}

function scrot_region_capture {
  scrot -s "${SCREENDIR}/${SCROT_FORMAT}"
}

function scrot_window_capture {
  scrot -u "${SCREENDIR}/${SCROT_FORMAT}"
}

function scrot_full_capture {
  scrot "${SCREENDIR}/${SCROT_FORMAT}"
}

case "${CMD}" in
  region|window|full)
    mkdir -p "${SCREENDIR}"
    case "${TOOL}" in
      flameshot)
        case "${CMD}" in
          region|window)
            flameshot_gui_capture
            ;;
          full)
            flameshot_full_capture
            ;;
        esac
        ;;
      scrot)
        case "${CMD}" in
          region)
            scrot_region_capture
            ;;
          window)
            scrot_window_capture
            ;;
          full)
            scrot_full_capture
            ;;
        esac
        ;;
      *)
        echo "Error: Unknown or unsupported tool '${TOOL}'" >&2
        exit 1
        ;;
    esac
    exit $?
    ;;
  *)
    echo "Usage: $0 [region|window|full]" >/dev/stderr
    exit 1
    ;;
esac
