#!/bin/bash

set -ue

VER="v3.4.0"

FONTS=(
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/DejaVuSansMono.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/FiraCode.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/FiraMono.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/Hack.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/Inconsolata.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/OpenDyslexic.zip
)

if [ "$(uname)" = "Darwin" ]; then
  FPATH="${HOME}/Library/Fonts"
else
  FPATH="${HOME}/.local/share/fonts/nerdfonts"
fi

mkdir -p "${FPATH}"
cd "${FPATH}"

for f in "${FONTS[@]}"; do
  BN=$(basename "$f")
  wget -O "${FPATH}/${BN}" "$f"
  unzip -o -d "${FPATH}" "${FPATH}/${BN}"
done

if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -v
fi
