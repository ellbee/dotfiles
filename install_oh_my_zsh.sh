#! /bin/bash
set -e

if [ ! -d ~/.oh-my-zsh ]; then
  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
fi

if [ -e ~/.zshrc ]; then
  mv ~/.zshrc{,-backup}
fi

ln -s ~/dotfiles/configfiles/zshrc ~/.zshrc
sudo chsh -s $(which zsh) $(whoami)

if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-completions ]; then
  git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
fi
