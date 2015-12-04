#!/bin/bash

programs=(ack ag git node nvm pstree ranger 
  reattach-to-user-namespace rlwrap tmux trash tree vim zsh
)

for program in "${programs[@]}"; do
  brew install "${program}"
done
