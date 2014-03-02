#!/bin/bash

get_neobundle() {
    if [ ! -d ~/.vim/bundle/neobundle.vim ]; then
        echo "downloading neoBundle..."
        mkdir -p ~/.vim/bundle
        git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
    fi
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
        mkdir -p ~/.vim/backup/
    fi
    if [ ! -d ~/.vim/swap ]; then
        echo "creating vim swap dir"
        mkdir ~/.vim/swap/
    fi
}

install_oh_my_zsh() {
    git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
    chsh -s /bin/zsh
}

vim_swap_and_backup_dirs
get_neobundle
copy_dotfiles
