#! /bin/bash

set -e
apt install git
apt install build-essential
apt install ruby

# linuxbrew
ruby -e "$curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"

# zsh
brew install zsh
./install_oh_my_zsh.sh

# link dotfiles
./mysetup.sh
