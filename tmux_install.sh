#!/bin/bash

mkdir ~/build_from_source/
git clone https://github.com/tmux/tmux.git ~/build_from_source/tmux
cd ~/build_from_source/tmux
sh ./autogen.sh
./configure && make
