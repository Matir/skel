# Change to the root of the git repository.
# If not in a git repo, do nothing.
cdgr() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$git_root" ]; then
    cd "$git_root"
  fi
}
