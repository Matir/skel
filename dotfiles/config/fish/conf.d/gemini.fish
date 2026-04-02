# Bridge to Gemini CLI Context Management (Zsh-backed)
# This allows using the Zsh implementation from Fish to avoid dual maintenance.

# Ensure the base context directory exists
if set -q XDG_CONFIG_HOME
    set -gx GEMINI_CONTEXT_DIR $XDG_CONFIG_HOME/gemini
else
    set -gx GEMINI_CONTEXT_DIR $HOME/.config/gemini
end
mkdir -p "$GEMINI_CONTEXT_DIR"

# Path to the source of truth
set -l gemini_zsh_script "$HOME/.skel/dotfiles/zshrc.d/gemini.zsh"

function _gemini_context_bridge
    # Check if Zsh script exists
    if not test -f "$gemini_zsh_script"
        echo "Error: Gemini Zsh script not found at $gemini_zsh_script"
        return 1
    end

    # We use a temporary file to reliably pass the environment variable back
    set -l env_file (mktemp -t gemini_context.XXXXXX)
    
    # Run zsh with -e (exit on error):
    # 1. Source the context manager
    # 2. Run the requested command with arguments
    # 3. Write the resulting GEMINI_CLI_HOME to the temp file
    command zsh -ec "
        source '$gemini_zsh_script'
        $argv
        echo \"\$GEMINI_CLI_HOME\" > '$env_file'
    "
    set -l zsh_status $status
    
    # Only sync environment and clean up on success
    if test $zsh_status -eq 0
        set -l new_home (cat $env_file | string trim)
        if test -n "$new_home"
            set -gx GEMINI_CLI_HOME "$new_home"
        else
            set -e GEMINI_CLI_HOME
        end
    end

    rm -f $env_file
    return $zsh_status
end

# Wrapper functions
function gemini-context-use
    _gemini_context_bridge "gemini-context-use $argv"
end

function gemini-context-create
    _gemini_context_bridge "gemini-context-create $argv"
end

function gemini-context-list
    _gemini_context_bridge "gemini-context-list $argv"
end

function gemini-context-delete
    _gemini_context_bridge "gemini-context-delete $argv"
end

function gemini-context-rename
    _gemini_context_bridge "gemini-context-rename $argv"
end

function gemini-context-edit
    _gemini_context_bridge "gemini-context-edit $argv"
end

function gemini-context-current
    _gemini_context_bridge "gemini-context-current $argv"
end

function gemini-context-unset
    _gemini_context_bridge "gemini-context-unset $argv"
end

# Aliases
alias gemctx='gemini-context-use'

# Completion
function _gemini_context_list
    zsh -c "source '$gemini_zsh_script'; _gemini_context_list_internal"
end

complete -c gemini-context-use -f -a "(_gemini_context_list)"
complete -c gemctx -f -a "(_gemini_context_list)"
complete -c gemini-context-edit -f -a "(_gemini_context_list)"
complete -c gemini-context-delete -f -a "(_gemini_context_list)"
complete -c gemini-context-rename -f -a "(_gemini_context_list)"
