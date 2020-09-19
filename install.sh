#!/bin/bash
set -e

if [ -x "$(command -v brew)" ]; then
    sudo -u $SUDO_USER brew install vim || true
else
    vim_version=8.2.1539
    python3_command=python3

    DEBIAN_FRONTEND=noninteractive apt install -y \
        python3-dev curl build-essential make libncurses5-dev libncursesw5-dev gcc \
        libx11-dev libxtst-dev libxt-dev libsm-dev libxpm-dev

    if ! [ $(python3 -c "import sys; print(1 if sys.version_info.major >= 3 and sys.version_info.minor >= 6 else 0)") == 1 ]; then
        if ! [ -x "$(command -v python3.6-dev)" ] || \
             [ $(dpkg-query -W -f='${Status}' python3.6-dev 2>/dev/null | grep -c "ok installed") == 1 ]; then
            DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:deadsnakes/ppa
            DEBIAN_FRONEND=noninteractive apt update
            DEBIAN_FRONTEND=noninteractive apt install -y python3.6-dev
        fi
        python3_command=python3.6
    fi

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

    DEBIAN_FRONTEND=noninteractive apt purge -y vim

    make install
    cd $INSTALL_VIMRC_CURDIR
fi
cp .vimrc ~/.vimrc
INSTALL_VIMRC=1 vim
