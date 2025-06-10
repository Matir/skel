
if test -x /opt/homebrew/bin/brew
  /opt/homebrew/bin/brew shellenv fish | source
  if test -d (brew --prefix)"/share/fish/completions"
    set -p fish_complete_path (brew --prefix)/share/fish/completions
  end

  if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
  end
end

if command -q starship
  starship init fish --print-full-init | source
end

# Want this at the bottom to put this path first
fish_add_path --move --path {$HOME}/bin
