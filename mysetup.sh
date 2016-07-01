#!/bin/bash

set -e

create_dot_vim() {
  if [ ! -d ~/.vim ]; then
    echo "creating .vim file"
    mkdir -p ~/.vim/backup
  fi
  if [ ! -e ~/.vim/Ultisnips ]; then
    ln -s ~/dotfiles/configfiles/UltiSnips ~/.vim/UltiSnips
  fi
  if [ -e ~/.config/nvim ]; then
    rm -rf ~/.config/nvim
  fi
  ln -s ~/.vim ~/.config/nvim
}

copy_dotfiles() {
  echo "copying dotfiles into user directory"
  cd ~/dotfiles/configfiles
  for file in *; do
    if [ -f ~/dotfiles/configfiles/"$file" ]; then
      [ -f ~/."$file" ] && mv ~/."$file"{,-backup}
      echo "copying $file"
      ln -s ~/dotfiles/configfiles/"$file" ~/."$file"
    fi
  done
}

vim_swap_and_backup_dirs() {
  if [ ! -d ~/.vim/backup ]; then
    echo "creating vim backup dir"
    mkdir -p ~/.vim/backup
  fi
  if [ ! -d ~/.vim/swap ]; then
    echo "creating vim swap dir"
    mkdir ~/.vim/swap
  fi
}

vim_install_plug() {
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

create_dot_vim
vim_swap_and_backup_dirs
vim_install_plug
copy_dotfiles
