#! /bin/bash
set -e

git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
mv ~/.zshrc{,-backup}
 ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
ln -s ~/dotfiles/configfiles/zshrc ~/.zshrc
sudo chsh -s $(which zsh) $(whoami)
git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
