#!/bin/bash

programs=(
  ag elixir git neovim node nvm pstree ranger
  rlwrap tmux trash tree vim xz zsh
)

for program in "${programs[@]}"; do
  brew install "${program}"
done
