#! /bin/bash

set -e
sudo apt install git
sudo apt install build-essential
sudo apt install ruby

# linuxbrew
if [ ! -e /usr/bin/brew ]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
  sudo apt install linuxbrew-wrapper
fi

# zsh
sudo apt install zsh 
~/dotfiles/install_oh_my_zsh.sh

# link dotfiles
~/dotfiles/mysetup.sh
