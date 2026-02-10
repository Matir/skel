#!/bin/sh
# shellcheck disable=SC2039,SC2086

set -o nounset

prune_broken_symlinks() {
    ask=1
    dir="."
    
    if [ "${1:-}" = "-y" ]; then
        ask=0
        shift
    fi
    
    if [ -n "${1:-}" ]; then
        dir="$1"
    fi
    
    # Check if there are any broken symlinks first
    broken_links=$(find -L "$dir" -xdev -type l -print 2>/dev/null)
    if [ -z "$broken_links" ]; then
        return 0
    fi
    
    if [ "$ask" -eq 1 ]; then
        # Print broken links
        echo "$broken_links"
        
        printf "Delete these links? [y/N] "
        read -r reply
        case "$reply" in
            [yY]*)
                ;;
            *)
                echo "Aborted."
                return 0
                ;;
        esac
    fi
    
    # Perform deletion
    find -L "$dir" -xdev -type l -exec rm -- {} + 2>/dev/null
}

# Execute the function
prune_broken_symlinks "$@"
