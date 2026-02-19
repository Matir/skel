# Change to the root of the git repository.
# If not in a git repo, do nothing.
function cdgr
    set git_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$git_root"
        cd "$git_root"
    end
end
