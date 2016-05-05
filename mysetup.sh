#!/bin/bash

create_dot_vim() {
  mkdir ~/.vim
  ln -s ~./dotfiles/configfiles/UltiSnips ~/.vim/UltiSnips 
}

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

install_oh_my_zsh() {
  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
  chsh -s /bin/zsh
}

create_dot_vim
vim_swap_and_backup_dirs
vim_install_plug
copy_dotfiles
