# Cryptsetup alias
alias luksFormat 'cryptsetup luksFormat --type=luks2 --pbkdf-memory=2560000 --pbkdf=argon2id -i 15000 -s 512 -h sha256 -c aes-xts-plain64'

# Timestamp in a machine-sortable form
alias tstamp "date '+%Y%m%d-%H%M%S'"

# Prepare code for markdown
alias mdcode "sed 's/^/    /'"

# Intel format plz
alias objdump "command objdump -M intel"

# Drop caches for swap issues
alias drop_caches "echo 3 | sudo /usr/bin/tee /proc/sys/vm/drop_caches"

# dump acpi temperature
alias gettemp 'printf "%02.2f\n" (cat /sys/class/thermal/thermal_zone0/temp)e-3'

# get git working directory
alias gitroot "git rev-parse --show-toplevel"

# SSH without host key checking
alias sshanon "ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no"

# Straight to ipython
alias ipy "ipython3 --no-banner"

# Skip the header on bc
alias bc "command bc -q"

# Get a decently readable df
alias dfh "df -h -x tmpfs -x devtmpfs -x squashfs -x fuse -x efivarfs"

# Clear the GPG agent
alias clear-gpg-agent "echo RELOADAGENT | gpg-connect-agent"

# Battery details
alias bat-details 'upower -i (upower -e | grep battery)'

# Nvidia refresh rate
alias nvidia-refresh-rate 'nvidia-settings --display=:0 -q RefreshRate -t'

# Earthly ssh
alias earthly 'earthly --ssh-auth-sock ""'

# to clipboard
alias toclip 'xclip -selection clipboard'

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
