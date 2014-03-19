#!/bin/bash

disable_file_helper() {
    echo "disabling path helper"
    sudo chmod ugo-x /usr/libexec/path_helper
}

disable_file_helper
