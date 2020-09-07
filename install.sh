#!/bin/bash
if [ -x "$(command -v brew)" ]; then
    sudo -u $SUDO_USER brew install vim
else
    add-apt-repository -y ppa:jonathonf/vim
    apt update
    apt install -y vim
fi
cp .vimrc ~/.vimrc
INSTALL_VIMRC=1 vim
