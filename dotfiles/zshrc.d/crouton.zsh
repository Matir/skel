if command -v xiwi >/dev/null 2>&1; then
  function xiwibg {
    local tmpf=$(mktemp)
    echo Logging to ${tmpf}
    nohup xiwi "$@" >!${tmpf} 2>&1 &
  }
fi
