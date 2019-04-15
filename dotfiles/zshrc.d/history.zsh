histmode() {
  # This is very brittle as it assumes we're the only user of fc
  case "$1" in
    on)
      if [ "$HISTDISABLED" -ne 1 ] ; then
        echo "History is not disabled." >&2
        return 1
      fi
      fc -P
      HISTDISABLED=0
      echo "History enabled."
      ;;
    off)
      if [ "$HISTDISABLED" -eq 1 ] ; then
        echo "History is already disabled." >&2
        return 1
      fi
      HISTDISABLED=1
      fc -p /dev/null $HISTSIZE 0
      echo "History disabled."
      ;;
    *)
      echo "Unknown command." >&2
      ;;
  esac
}
