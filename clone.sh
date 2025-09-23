#!/bin/bash

set -ue

# --- Helper function to install git ---
install_git() {
  echo "Git not found. Attempting to install..." >&2
  case "$(uname)" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        echo "Using Homebrew to install git..." >&2
        brew install git
      else
        echo "Error: Homebrew not found on your macOS system." >&2
        echo "Please install Homebrew first by visiting https://brew.sh/ then run this script again." >&2
        return 1
      fi
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        echo "Using apt-get to install git..." >&2
        if [ "${EUID:-$(id -u)}" -ne 0 ]; then
          sudo apt-get update && sudo apt-get install -y git
        else
          apt-get update && apt-get install -y git
        fi
      else
        echo "Error: This script requires 'apt-get' on Linux to install git." >&2
        echo "Please install git using your system's package manager and run this script again." >&2
        return 1
      fi
      ;;
    *)
      echo "Error: Unsupported operating system '$(uname)'." >&2
      echo "Please install git manually and run this script again." >&2
      return 1
      ;;
  esac
}

# --- Main script logic ---
installer_main() {
  # 1. Check for git, and try to install it if it's missing.
  if ! command -v git >/dev/null 2>&1; then
    install_git
    # Final check after attempting installation
    if ! command -v git >/dev/null 2>&1; then
      echo "ERROR: git installation failed or was not found." >&2
      echo "Please install git manually and re-run this script." >&2
      exit 1
    fi
  fi

  # 2. Clone the repository if it doesn't exist
  local dest="${HOME}/.skel"
  if [ -d "${dest}" ]; then
    echo "Repository already exists in ${dest}. Skipping clone." >&2
  else
    echo "Cloning repository..." >&2
    git clone --depth 1 https://github.com/Matir/skel.git "${dest}"
  fi

  # 3. Run the main installer
  echo "Running main installer..." >&2
  "${dest}/install.sh"
}

installer_main

