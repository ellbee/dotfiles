#!/bin/bash

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
    cd configfiles
    for file in *; do
        echo "copying $file"
        rm ~/."$file"
        ln -s ~/dotfiles/configfiles/"$file" ~/."$file"
    done
}

getNeobundle
copyDotfiles
