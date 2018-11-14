#!/bin/bash

disable_path_helper() {
  echo "disabling path helper"
  sudo chmod ugo-x /usr/libexec/path_helper
}

# see https://github.com/neovim/neovim/issues/2048#issuecomment-78045837
change_delete_code_from_ctrl_h_to_ascii_del() {
  infocmp $TERM | sed 's/kbs=^[hH]/kbs=\\177/' > $TERM.ti
  tic $TERM.ti
}

install_asdf_plugins() {
  asdf plugin-add elixir
  asdf plugin-add erlang
  asdf plugin-add nodejs
  bash $ASDF_DIR/plugins/nodejs/bin/import-release-team-keyring 
}

disable_path_helper
change_delete_code_from_ctrl_h_to_ascii_del

git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.1
source $HOME/.asdf/asdf.sh
install_asdf_plugins
