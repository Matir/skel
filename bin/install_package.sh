#!/bin/bash

# Attempt to install packages regardless of OS

set -ue

is_sourced() {
  if [ -n "${ZSH_VERSION:-}" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

# Format is <apt name>:<manager>:<alternate name>
# Use "-" for alternate name if not available
PACKAGE_ALIASES=$(cat <<'EOF'
binfmt-support:brew:-
cryptsetup:brew:-
lvm2:brew:-
EOF
)

package_alias() {
  local manager="$1"
  local package="$2"
  local alias=$(echo "$PACKAGE_ALIASES" | \
    awk -F: -v manager="${manager}" -v package="${package}" \
    '$1 == package && $2 == manager { print $3 }' 2>/dev/null)
  echo "${alias:-${package}}"
}

install_package() {
  local package="$1"

  # Check for apt-get
  if command -v apt-get &> /dev/null; then
    package=$(package_alias apt "${package}")
    if [ "$package" == "-" ] ; then
      echo "Package not available on this platform"
      return 1
    fi
    echo "Installing '$package' using apt-get..."
    sudo apt-get install -y "$package"
    return 0
  elif command -v yum &> /dev/null; then
    package=$(package_alias yum "${package}")
    if [ "$package" == "-" ] ; then
      echo "Package not available on this platform"
      return 1
    fi
    echo "Installing '$package' using yum..."
    sudo yum install -y "$package"
    return 0
  elif command -v pacman &> /dev/null; then
    package=$(package_alias pacman "${package}")
    if [ "$package" == "-" ] ; then
      echo "Package not available on this platform"
      return 1
    fi
    echo "Installing '$package' using pacman..."
    sudo pacman -S "$package"
    return 0
  # For macOS, assume Homebrew is installed
  elif command -v brew &> /dev/null; then
    package=$(package_alias brew "${package}")
    if [ "$package" == "-" ] ; then
      echo "Package not available on this platform"
      return 1
    fi
    echo "Installing '$package' using Homebrew..."
    brew install "$package"
    return 0
  else
    echo "Error: No suitable package manager found."
    return 1
  fi
}

is_sourced || {
  # Get the package name from the command line argument
  if [ $# -eq 0 ]; then
    echo "Usage: $0 <package_name>"
    exit 1
  fi

  package_name="$1"

  # Call the install function
  install_package "$package_name"
}
