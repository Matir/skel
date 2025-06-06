
if test -x /opt/homebrew/bin/brew
  /opt/homebrew/bin/brew shellenv fish | source
end

if command -q starship
  starship init fish --print-full-init | source
end

# Want this at the bottom to put this path first
fish_add_path --move --path {$HOME}/bin
