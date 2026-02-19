if test -x /opt/homebrew/bin/brew
  /opt/homebrew/bin/brew shellenv fish | source
  if test -d (brew --prefix)"/share/fish/completions"
    set -p fish_complete_path (brew --prefix)/share/fish/completions
  end

  if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
  end

  # mise, if installed
  if type -q mise
    mise hook fish | source
  end
end

if command -q starship
  starship init fish --print-full-init | source
end

function install_fisher
  if not test -e ~/.config/fish/functions/fisher.fish
    echo "Installing Fisher for fish shell..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
  end
end

if status --is-interactive
  install_fisher
end

# Want this at the bottom to put this path first
fish_add_path --move --path {$HOME}/bin
