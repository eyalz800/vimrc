#!/bin/bash
set +e

if [ -x "$(command -v brew)" ]; then
    sudo -u $SUDO_USER brew install vim
else
    if ! [ -x "$(command -v python3)" ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y python3
    fi

    if ! [ $(python3 --version | python3 -c "import sys; major, minor = [int(c) for c in sys.stdin.read().split(\" \")[1].split(\".\")][:2]; print(1 if major >= 3 and minor >= 6 else 0)") == 1 ]; then
        if ! [ -x "$(command -v python3.6)" ]; then
            add-apt-repository -y ppa:deadsnakes/ppa
            apt update
            DEBIAN_FRONTEND=noninteractive apt install -y python3.6-dev
        fi
        DEBIAN_FRONTEND=noninteractive apt install -y curl build-essential make libncurses5-dev libncursesw5-dev gcc
        curl -fLo ~/.vim/tmp/vim/vim.tar.gz --create-dirs \
            https://github.com/vim/vim/archive/v8.2.0.tar.gz
        INSTALL_VIMRC_CURDIR=`pwd`
        cd ~/.vim/tmp/vim
        tar -xzf ~/.vim/tmp/vim/vim.tar.gz
        cd vim-8.2.0
        ./configure --with-features=huge \
            --prefix=/usr \
            --enable-cscope \
            --enable-python3interp \
            --with-python3-command=python3.6 \
            --with-python3-config-dir=/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu
        make -j
        make install
        cd $INSTALL_VIMRC_CURDIR
    else
        add-apt-repository -y ppa:jonathonf/vim
        apt update
        apt install -y vim
    fi
fi
cp .vimrc ~/.vimrc
INSTALL_VIMRC=1 vim
