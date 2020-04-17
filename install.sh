#!/usr/bin/env bash

set -e

sudo apt update
sudo apt --assume-yes install zsh
sudo chsh -s $(which zsh)

touch ~/.zshrc
zsh ~/.dotfiles/setup_prezto.sh
zsh