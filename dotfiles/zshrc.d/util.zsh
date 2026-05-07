# utility function to "open" a file
o() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$@"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$@"
  else
    echo "Unknown OS"
  fi
}

# Copy from stdin to the system clipboard
syscopy() {
    if command -v pbcopy >/dev/null 2>&1; then
        # macOS
        pbcopy "$@"
    elif command -v wl-copy >/dev/null 2>&1; then
        # Linux Wayland
        wl-copy "$@"
    elif command -v xclip >/dev/null 2>&1; then
        # Linux X11
        xclip -selection clipboard "$@"
    elif command -v xsel >/dev/null 2>&1; then
        # Linux X11 (alternative)
        xsel --clipboard --input "$@"
    elif command -v clip.exe >/dev/null 2>&1; then
        # Windows WSL
        clip.exe "$@"
    else
        echo "Error: No clipboard utility found. Please install pbcopy, wl-copy, xclip, or xsel." >&2
        return 1
    fi
}

# Paste from the system clipboard to stdout
syspaste() {
    if command -v pbpaste >/dev/null 2>&1; then
        # macOS
        pbpaste "$@"
    elif command -v wl-paste >/dev/null 2>&1; then
        # Linux Wayland
        wl-paste "$@"
    elif command -v xclip >/dev/null 2>&1; then
        # Linux X11
        xclip -selection clipboard -o "$@"
    elif command -v xsel >/dev/null 2>&1; then
        # Linux X11 (alternative)
        xsel --clipboard --output "$@"
    elif command -v powershell.exe >/dev/null 2>&1; then
        # Windows WSL
        powershell.exe -noprofile -command Get-Clipboard "$@"
    else
        echo "Error: No clipboard utility found. Please install pbpaste, wl-paste, xclip, or xsel." >&2
        return 1
    fi
}
