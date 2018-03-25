#! /bin/bash

set -e
sudo apt install git
sudo apt install build-essential
sudo apt install ruby

# zsh
sudo apt install zsh 
~/dotfiles/install_oh_my_zsh.sh

# link dotfiles
~/dotfiles/mysetup.sh

git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
