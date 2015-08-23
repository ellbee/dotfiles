#!/bin/bash

disable_path_helper() {
    echo "disabling path helper"
    sudo chmod ugo-x /usr/libexec/path_helper
}

disable_path_helper
