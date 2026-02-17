# Zsh Inter-plugin Manager (zi) setup
# https://github.com/z-shell/zi

# Check if the zi directory exists to proceed with setup
if [[ -d "${HOME}/.zi" ]]; then
  # Define ZI home and bin directories
  typeset -A ZI
  ZI[HOME_DIR]="${HOME}/.zi"
  ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"

  # Source zi if the main script exists, otherwise the installation is incomplete
  if [[ -f "${ZI[BIN_DIR]}/zi.zsh" ]]; then
    source "${ZI[BIN_DIR]}/zi.zsh"

    # Enable zi completions
    autoload -Uz _zi
    (( ${+_comps} )) && _comps[zi]=_zi

    # Add zi modules here
    zi ice ver"53da496"
    zi load "wfxr/forgit"
  fi
else
  # Path for the acknowledgment file.
  # We use a file inside the ~/.zi directory to keep related files together.
  local ack_file="${HOME}/.zi/no_zi_ack"

  # Check if the user has acknowledged the absence of zi to prevent nagging.
  if [[ ! -f "${ack_file}" ]]; then
    # If ~/.zi does not exist, define a helper function to install it.
    _install_zi() {
      echo "zi is not installed. Attempting to install to ~/.zi..."

      if ! command -v git &>/dev/null; then
          echo "Error: git is not installed. Please install git to continue." >&2
          return 1
      fi

      # Create the directory structure
      echo "Creating installation directory..."
      mkdir -p "${HOME}/.zi/bin"

      # Perform a shallow clone of the repository
      echo "Cloning the zi repository..."
      if command git clone --depth 1 https://github.com/z-shell/zi.git "${HOME}/.zi/bin"; then
        echo "zi has been installed successfully."
        echo "Reloading shell to activate..."
        exec zsh -li
      else
        echo "Error: Failed to clone the zi repository." >&2
        # Clean up created directories on failure
        rm -rf "${HOME}/.zi"
        return 1
      fi
    }

    # Define a function to acknowledge the absence of zi and suppress the warning.
    _ack_no_zi() {
      echo "Acknowledging the absence of zi. The warning will be suppressed on the next shell start."
      mkdir -p "$(dirname "${ack_file}")"
      touch "${ack_file}"
      echo "To re-enable the warning, remove the file: ${ack_file}"
    }

    echo "zi plugin manager is not installed. Run '_install_zi' to install, or '_ack_no_zi' to suppress this warning."
  fi
fi
