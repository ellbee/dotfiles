#!/bin/bash

copy_dotfiles() {
  echo "copying dotfiles into user directory"
  cd configfiles
  for file in *; do
    echo "copying $file"
    rm ~/."$file"
    ln -s ~/dotfiles/configfiles/"$file" ~/."$file"
  done
}

vim_swap_and_backup_dirs() {
  if [ ! -d ~/.config/nvim/backup ]; then
    echo "creating vim backup dir"
    mkdir -p ~/.config/nvim/backup
  fi
  if [ ! -d ~/.config/nvim/swap ]; then
    echo "creating vim swap dir"
    mkdir ~/.config/nvim/swap
  fi
}

install_oh_my_zsh() {
  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
  chsh -s /bin/zsh
}

vim_swap_and_backup_dirs
copy_dotfiles
