#!/bin/bash

programs=(ag git neovim node nvm pstree ranger
  reattach-to-user-namespace rlwrap tmux trash tree vim xz zsh
)

for program in "${programs[@]}"; do
  brew install "${program}"
done
