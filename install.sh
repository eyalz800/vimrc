#!/bin/bash
add-apt-repository -y ppa:jonathonf/vim
apt update
apt install -y vim
cp .vimrc ~/.vimrc
INSTALL_VIMRC=1 vim
