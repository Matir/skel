#!/bin/bash

set -ue

VER="v2.2.2"

FONTS=(
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/DejaVuSansMono.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/FiraCode.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/FiraMono.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/Hack.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/Inconsolata.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/${VER}/OpenDyslexic.zip
)

FPATH=${HOME}/.fonts/nerdfonts
mkdir -p ${FPATH}
cd ${FPATH}

for f in ${FONTS[@]}; do
  BN=$(basename $f)
  wget -O ${FPATH}/${BN} ${f}
  unzip -o -d ${FPATH} ${FPATH}/${BN}
done

fc-cache -v
