#!/bin/bash
#
# Installs Ansible, trying user-space methods first before falling back to sudo.
# This script is designed to be idempotent and safe to run multiple times.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Helper Functions ---
info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

# --- Main Logic ---

# 1. Check if Ansible is already installed
if command -v ansible >/dev/null 2>&1; then
    info "Ansible is already installed at $(command -v ansible)."
    exit 0
fi
info "Ansible not found. Attempting installation..."

# 2. Try user-space installation (no sudo)
info "--- Attempting user-space installation (no sudo required) ---"

# Try pipx first, as it's the cleanest user-space method
if command -v pipx >/dev/null 2>&1; then
    info "Found pipx. Trying to install Ansible with it..."
    if pipx install ansible;
     then
        # pipx requires adding ~/.local/bin to PATH, which might not be sourced yet.
        # Check the executable directly.
        if [[ -x "${HOME}/.local/bin/ansible" ]]; then
            info "Ansible installed successfully with pipx."
            info "Please ensure '${HOME}/.local/bin' is in your PATH."
            info "You may need to restart your shell or run: export PATH=\"$HOME/.local/bin:$PATH\""
            exit 0
        else
            warn "pipx install seemed to succeed, but ansible executable not found where expected."
        fi
    else
        warn "pipx install ansible failed."
    fi
fi

# Try Python's venv module if pipx failed or wasn't present
VENV_PATH="${HOME}/.local/share/ansible_venv"
# Create a temp path to avoid clobbering a failed install
VENV_TEST_PATH="/tmp/ansible_venv_test_$$"
if python3 -m venv "${VENV_TEST_PATH}" >/dev/null 2>&1; then
    rm -rf "${VENV_TEST_PATH}" # Clean up test
    info "Python's venv module is available. Creating a virtual environment at ${VENV_PATH}..."
    python3 -m venv "${VENV_PATH}"
    if "${VENV_PATH}/bin/pip" install --quiet ansible;
     then
        info "Ansible installed successfully into a virtual environment."
        info "To use it, run: '${VENV_PATH}/bin/ansible'"
        info "To make it available everywhere, add its bin directory to your PATH:"
        info "  echo 'export PATH="${VENV_PATH}/bin:$PATH"' >> ~/.profile"
        info "(You may need to source ~/.profile or restart your shell)."
        exit 0
    else
        warn "Failed to install ansible into the virtual environment."
        rm -rf "${VENV_PATH}" # Clean up failed attempt
    fi
else
    info "Python's venv module not available or failed to create a test environment."
fi

# 3. Fallback to sudo installation
info "--- User-space installation failed. Falling back to system-wide installation (sudo required) ---"

if ! command -v sudo >/dev/null 2>&1; then
    error "sudo command not found. Cannot attempt system-wide installation. Aborting."
fi

# Prompt for sudo password upfront so it doesn't happen in the middle of the script
info "Sudo privileges are required. You may be prompted for your password."
if ! sudo -v; then
    error "Failed to acquire sudo privileges. Aborting."
fi

# Detect package manager and install
if command -v apt-get >/dev/null 2>&1; then
    info "Detected Debian-based system (apt)."
    sudo apt-get update -y
    info "Attempting to install 'ansible' package..."
    if sudo apt-get install -y ansible;
     then
        info "System package 'ansible' installed successfully."
    else
        warn "Failed to install 'ansible' package directly. Trying to install prerequisites for user-space install..."
        if sudo apt-get install -y pipx;
         then
             info "Installed pipx. Attempting to install Ansible with it..."
             if pipx install ansible;
              then
                info "Ansible installed successfully with pipx."
                info "Please ensure '${HOME}/.local/bin' is in your PATH."
                exit 0
             fi
        else
            error "Failed to install 'ansible' or 'pipx' via apt. Aborting."
        fi
    fi
elif command -v dnf >/dev/null 2>&1; then
    info "Detected Red Hat-based system (dnf)."
    info "Attempting to install 'ansible-core' package..."
    if ! sudo dnf install -y ansible-core;
     then
        error "Failed to install ansible-core via dnf. Aborting."
    fi
elif command -v pacman >/dev/null 2>&1; then
    info "Detected Arch-based system (pacman)."
    info "Attempting to install 'ansible' package..."
    if ! sudo pacman -Syu --noconfirm ansible;
     then
        error "Failed to install ansible via pacman. Aborting."
    fi
elif command -v brew >/dev/null 2>&1; then
    info "Detected macOS (brew)."
    info "Attempting to install 'ansible' package..."
    if ! brew install ansible;
     then
        error "Failed to install ansible via brew. Aborting."
    fi
else
    error "Could not detect a known package manager (apt, dnf, pacman, brew). Aborting."
fi

# 4. Final verification
info "--- Verifying final installation ---"
if command -v ansible >/dev/null 2>&1; then
    info "Ansible successfully installed at $(command -v ansible)."
    exit 0
else
    error "Installation attempted but the 'ansible' command is still not available. Please check the output for errors."
fi
