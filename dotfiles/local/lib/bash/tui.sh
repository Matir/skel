#!/usr/bin/env bash

# verify array support
if eval '_t=(1)' 2>/dev/null; then
  unset _t
else
  echo "Error: This script requires a shell with array and local variable support (like Bash or Zsh)." >&2
  (return 0 2>/dev/null) && return 1 || exit 1
fi

select_entry() {
  # interactive selection from a list
  # usage: select_entry "$prompt" "$default"
  local prompt="${1:-Select an entry}"
  local default_choice="${2:-}"
  local input_data

  if [[ -t 0 ]] ; then
    echo "select_entry should be used with piped input" >&2
    return 1
  fi

  input_data=$(cat)

  if [[ -z "$input_data" ]]; then
    return 1
  fi

  local display_prompt="$prompt"
  if [[ -n "$default_choice" ]]; then
    display_prompt="$prompt [$default_choice]"
  fi

  if [[ -z "${NO_FZF:-}" ]] && command -v fzf >/dev/null 2>&1; then
    local fzf_input="$input_data"

    # If a default is provided, move that line to the very top
    # so fzf's cursor starts on it.
    if [[ -n "$default_choice" ]]; then
      local default_line
      default_line=$(echo "$input_data" | grep "^$default_choice\([[:space:]]\|$\)")
      if [[ -n "$default_line" ]]; then
        # Remove the original line and prepend it to the top
        fzf_input=$(printf "%s\n%s" "$default_line" "$(echo "$input_data" | grep -v "^$default_choice\([[:space:]]\|$\)")")
      fi
    fi

    local choice
    choice=$(echo "$fzf_input" | \
      fzf --prompt="$prompt: " --accept-nth 1 --height '~100%' --reverse)
    if [[ -z "$choice" ]]; then
      [[ -n "$default_choice" ]] && echo "$default_choice" && return 0
      return 1
    fi
    echo "${choice}"
    return 0
  else
    local i=1
    local lines=()

    printf "\n--- %s ---\n" "$prompt" >&2

    # Load lines into an array
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      printf "%2d) %s\n" "$i" "$line"
      lines[i]="$line"
      ((i++))
    done <<< "$input_data"

    local count=$((i - 1))

    printf "%s (1-%d or word): " "$display_prompt" "$count" >&2
    read -r choice

    if [[ -z "$choice" ]]; then
      if [[ -n "$default_choice" ]]; then
        echo "$default_choice"
        return 0
      else
        return 1
      fi
    fi

    # Match logic
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
      echo "${lines[$choice]}" | awk '{print $1}'
    else
      # Iterate to find word match
      local found=0
      for (( j=1; j<=count; j++ )); do
        local current_line="${lines[$j]}"
        local first_word="${current_line%%[[:space:]]*}"
        if [[ "$choice" == "$first_word" ]]; then
          echo "$first_word"
          found=1
          break
        fi
      done

      if [[ $found -eq 0 ]]; then
        echo "Invalid selection: $choice" >&2
        return 1
      fi
    fi
  fi
}
