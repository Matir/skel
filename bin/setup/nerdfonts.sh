#!/bin/bash

set -ue

FONTS=(
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/DejaVuSansMono.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/FiraCode.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/FiraMono.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Hack.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Inconsolata.zip
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/OpenDyslexic.zip
)

echo ${FONTS}

FPATH=${HOME}/.fonts/nerdfonts
mkdir -p ${FPATH}
cd ${FPATH}

for f in ${FONTS[@]}; do
  echo ${f}
  BN=$(basename $f)
  wget -O ${FPATH}/${BN} ${f}
  unzip -o -d ${FPATH} ${FPATH}/${BN}
done
