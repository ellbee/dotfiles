#!/bin/sh

getNeobundle() {
    mkdir -p ~/.vim/bundle
    git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
}

copyDotfiles() {
    cd ~/dotfiles
    cp .vim ~
    cp .tmux.conf ~
    cp .gitconfig .gitignore_global .githelpers ~
}

copyDotfiles()
getNeobundle()
