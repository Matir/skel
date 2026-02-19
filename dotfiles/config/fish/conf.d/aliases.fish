# This script reads a bash-formatted alias file (~/.aliases) and creates
# equivalent fish aliases. This allows for sharing aliases between bash and fish.

# Path to the bash alias file
set bash_alias_file ~/.aliases

# Check if the alias file exists
if test -f "$bash_alias_file"
  # Read the file line by line
  while read -l line
    # Skip comments and empty lines
    if string match -q -r '^\s*#' "$line" || test -z "$line"
      continue
    end

    # Check if the line defines an alias
    if string match -q -r '^\s*alias\s+' "$line"
      # Remove the 'alias ' prefix
      set -l definition (string replace -r '^\s*alias\s+' '' "$line")
      
      # Split the definition into name and value at the first '='
      set -l parts (string split -m 1 '=' "$definition")
      set -l alias_name $parts[1]
      set -l alias_value $parts[2]
      
      # Remove leading/trailing quotes from the value
      set -l alias_value (string trim -c "'"" "$alias_value")
      
      # Define the fish alias
      alias $alias_name "$alias_value"
    end
  end < "$bash_alias_file"
end

# Specific aliases that are not in the bash file

# On some systems, bat is batcat
if not command -v bat >/dev/null 2>&1
  if command -v batcat >/dev/null 2>&1
    alias bat (command -v batcat)
  end
end

# FFUF aliases
if command -v ffuf >/dev/null 2>&1
  if test -d $HOME/tools/seclists
    alias ffuf-files "ffuf -c -w $HOME/tools/seclists/Discovery/Web-Content/raft-large-files.txt"
    alias ffuf-dirs "ffuf -c -w $HOME/tools/seclists/Discovery/Web-Content/raft-large-directories.txt"
    alias ffuf-quick "ffuf -c -w $HOME/tools/seclists/Discovery/Web-Content/quickhits.txt"
  end
end

if grep --help 2>/dev/null | grep -q 'color'
  # Should have a better way to check for GNU versions
  alias grep 'grep --color=auto'
  alias egrep 'egrep --color=auto'
  alias fgrep 'fgrep --color=auto'
end

# Detect which `ls` flavor is in use and use the right flag for colors.
if ls --help 2>&1 | grep -q -- '--color'
  alias ls 'ls --color=auto' # GNU `ls`
else if test (uname) = "Darwin"
  alias ls 'ls -G' # macOS `ls`
end