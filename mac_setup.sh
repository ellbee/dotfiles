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
  asdf plugin-add nodejs
  asdf plugin-add elixir
  asdf plugin-add erlang
}

disable_path_helper
change_delete_code_from_ctrl_h_to_ascii_del
install_asdf_plugins
