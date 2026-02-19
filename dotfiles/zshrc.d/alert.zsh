#!/usr/bin/env zsh

# A function to run a command and send a notification when it's done.
# Usage: alert sleep 10

alert() {
  # Run the command passed as arguments
  "$@"
  
  # Capture the exit code
  local ret=$?
  
  # Determine the icon based on success or failure
  local icon
  if [ $ret -eq 0 ]; then
    icon="terminal"
  else
    icon="error"
  fi
  
  # Send the notification with the executed command
  notify-send --urgency=low -i "$icon" "Finished: '$@'"
  
  # Return the original exit code
  return $ret
}
