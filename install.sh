#!/bin/bash
set -e

if [ -x "$(command -v brew)" ]; then
    sudo -u $SUDO_USER brew install vim || true
else
    vim_version=8.2.1539
    python3_command=python3

    if ! [ -x "$(command -v $python3_command)" ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y python3
    fi

    if ! [ $(python3 -c "import sys; print(1 if sys.version_info.major >= 3 and sys.version_info.minor >= 6 else 0)") == 1 ]; then
        if ! [ -x "$(command -v python3.6)" ]; then
            add-apt-repository -y ppa:deadsnakes/ppa
            apt update
            DEBIAN_FRONTEND=noninteractive apt install -y python3.6-dev
        fi
        python3_command=python3.6
    fi

    DEBIAN_FRONTEND=noninteractive apt install -y \
        curl build-essential make libncurses5-dev libncursesw5-dev gcc \
        libx11-dev libxtst-dev libxt-dev libsm-dev libxpm-dev
    DEBIAN_FRONTEND=noninteractive apt purge -y vim

    if ! [ -d ~/.vim/tmp/vim/vim-$vim-version ]
        curl -fLo ~/.vim/tmp/vim/vim.tar.gz --create-dirs \
            https://github.com/vim/vim/archive/v$vim_version.tar.gz
    fi

    INSTALL_VIMRC_CURDIR=`pwd`
    cd ~/.vim/tmp/vim
    tar -xzf ~/.vim/tmp/vim/vim.tar.gz
    cd vim-$vim_version
    make distclean
    ./configure --with-features=huge \
        --enable-fail-if-missing \
        --prefix=/usr \
        --enable-cscope \
        --enable-python3interp \
        --enable-clipboard \
        --enable-xterm_clipboard \
        --with-python3-command=$python3_command
    make -j
    make install
    cd $INSTALL_VIMRC_CURDIR
fi
cp .vimrc ~/.vimrc
INSTALL_VIMRC=1 vim
