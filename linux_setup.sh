#! /bin/bash

set -e
sudo apt install git
sudo apt install build-essential
sudo apt install ruby

# linuxbrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
sudo apt install linuxbrew-wrapper

# zsh
brew install zsh
./install_oh_my_zsh.sh

# link dotfiles
./mysetup.sh
