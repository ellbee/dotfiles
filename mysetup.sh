#!/bin/sh

getNeobundle() {
    if [ -d ~/.vim/bundle/neobundle.vim ]; then
        echo "neoBundle already downloaded"
    else
        mkdir -p ~/.vim/bundle
        git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
    fi
}

copyDotfiles() {
    echo "copying dotfiles into user directory"
    cd ~/dotfiles
    cp .vimrc ~
    cp .tmux.conf ~
    cp .gitconfig .gitignore_global .githelpers ~
}

getNeobundle
copyDotfiles
