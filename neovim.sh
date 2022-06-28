#!/bin/bash

ln -s ~/.vim ${XDG_CONFIG_HOME:=~/.config/nvim}
ln -s ~/.vimrc ~/.vim/init.vim

curl -fLo ~/./config/nvim/autoload/plug.vim --create-dirs \
  https://raw.github.com/junegunn/vim-plug/master/plug.vim
