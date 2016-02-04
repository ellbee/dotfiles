#!/bin/bash

mkdir -p ${XDG_CONFIG_HOME:=$HOME/.config/nvim}
ln -s ~/.vim $XDG_CONFIG_HOME/nvim
ln -s ~/.vimrc $XDG_CONFIG_HOME/nvim/init.vim

curl -fLo ~/./config/nvim/autoload/plug.vim --create-dirs \
  https://raw.github.com/junegunn/vim-plug/master/plug.vim

sudo pip2 install neovim
sudo pip3 install neovim
