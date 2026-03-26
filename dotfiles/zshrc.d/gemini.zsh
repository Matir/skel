# Gemini CLI Context Management

# Base directory for Gemini contexts
export GEMINI_CONTEXT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gemini"

# Ensure the base context directory exists
mkdir -p "$GEMINI_CONTEXT_DIR"

# Template settings file
GEMINI_TEMPLATE_SETTINGS="${HOME}/.skel/dotfiles/config/gemini/settings.json"

# Create a new Gemini context
gemini-context-create() {
  if [ -z "$1" ]; then
    echo "Usage: gemini-context-create <name>"
    return 1
  fi

  local context_name="$1"
  local context_path="$GEMINI_CONTEXT_DIR/$context_name"

  if [[ "$context_name" =~ [/] ]]; then
    echo "Error: Context name cannot contain slashes."
    return 1
  fi

  if [ -d "$context_path" ]; then
    echo "Error: Context '$context_name' already exists at $context_path"
    return 1
  fi

  echo "Creating context '$context_name' at $context_path"
  mkdir -p "$context_path/.gemini"

  if [ -f "$GEMINI_TEMPLATE_SETTINGS" ]; then
    cp "$GEMINI_TEMPLATE_SETTINGS" "$context_path/.gemini/settings.json"
    echo "Initialized with template settings."
  else
    echo "Warning: Template settings not found at $GEMINI_TEMPLATE_SETTINGS"
    touch "$context_path/.gemini/settings.json"
  fi
  echo "Context '$context_name' created."
}

# List available Gemini contexts
_gemini_context_list_internal() {
  command ls "$GEMINI_CONTEXT_DIR" 2>/dev/null
}

gemini-context-list() {
  echo "Available Gemini contexts:"
  local contexts=$(_gemini_context_list_internal)
  if [ -z "$contexts" ]; then
    echo "  (No contexts found)"
    return
  fi
  for context in $contexts; do
    if [ -d "$GEMINI_CONTEXT_DIR/$context" ]; then
      echo "  $context"
    fi
  done
}

# Use a specific Gemini context
gemini-context-use() {
  local context_name
  local quiet=0

  if [ "$1" = "-q" ] || [ "$1" = "--quiet" ]; then
    quiet=1
    shift
  fi

  if [ -z "$1" ]; then
    if command -v fzf >/dev/null; then
      context_name=$(_gemini_context_list_internal | fzf --prompt="Select Gemini Context: ")
      if [ -z "$context_name" ]; then
        return 1
      fi
    else
      echo "Usage: gemini-context-use [-q] <name>"
      echo "fzf not found for interactive selection."
      gemini-context-list
      return 1
    fi
  else
    context_name="$1"
  fi

  local context_path="$GEMINI_CONTEXT_DIR/$context_name"

  if [ ! -d "$context_path" ]; then
    [[ "$quiet" -eq 0 ]] && echo "Error: Context '$context_name' not found at $context_path"
    [[ "$quiet" -eq 0 ]] && gemini-context-list
    return 1
  fi

  export GEMINI_CLI_HOME="$context_path"
  [[ "$quiet" -eq 0 ]] && echo "Switched to Gemini context '$context_name' (GEMINI_CLI_HOME=$GEMINI_CLI_HOME)"
}

# Edit a context's settings
gemini-context-edit() {
  local context_name
  if [ -z "$1" ]; then
    if command -v fzf >/dev/null; then
      context_name=$(_gemini_context_list_internal | fzf --prompt="Select Gemini Context to Edit: ")
      if [ -z "$context_name" ]; then
        return 1
      fi
    else
      echo "Usage: gemini-context-edit <name>"
      gemini-context-list
      return 1
    fi
  else
    context_name="$1"
  fi

  local context_path="$GEMINI_CONTEXT_DIR/$context_name"
  local settings_file="$context_path/.gemini/settings.json"

  if [ ! -d "$context_path" ]; then
    echo "Error: Context '$context_name' not found."
    return 1
  fi

  if [ ! -f "$settings_file" ]; then
    echo "Error: settings.json not found for context '$context_name'."
    return 1
  fi

  ${EDITOR:-vim} "$settings_file"
}

# Show the current Gemini context
gemini-context-current() {
  if [ -n "$GEMINI_CLI_HOME" ]; then
    local current_context=$(basename "$GEMINI_CLI_HOME")
    if [ "$GEMINI_CONTEXT_DIR/$current_context" = "$GEMINI_CLI_HOME" ]; then
      echo "Current Gemini context: $current_context"
    else
      echo "Current Gemini context: Custom"
    fi
    echo "GEMINI_CLI_HOME=$GEMINI_CLI_HOME"
  else
    echo "No Gemini context set, using default."
  fi
}

# Unset the current Gemini context
gemini-context-unset() {
  unset GEMINI_CLI_HOME
  echo "Unset Gemini context, reverted to default."
}

# Alias for gemini-context-use
alias gemctx='gemini-context-use'

# Zsh Completion for gemini-context-use and gemctx
_gemini_contexts() {
  local contexts
  contexts=($(_gemini_context_list_internal))
  _describe 'gemini contexts' contexts
}
compdef _gemini_contexts gemini-context-use
compdef _gemini_contexts gemctx
compdef _gemini_contexts gemini-context-edit
