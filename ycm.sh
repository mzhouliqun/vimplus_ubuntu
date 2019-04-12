#!/bin/bash
#apt purge --auto-remove vim
apt-get update
apt-get install gcc g++ makev -y
apt-get install vim vim-gtk3 vim-tiny neovim vim-athena vim-gtk vim-nox -y
apt-get install python-pip curl git libncurses5-dev python-dev python3-dev build-essential cmake clang libclang-dev -y
curl -fLo ~/.vim/autoload/plug.vim --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
touch /root/.vimrc
cat /root/.vimrc | grep plug#begin > /dev/null 2>&1
if [ "$?" != "0" ];
then
echo "call plug#begin('~/.vim/plugged')
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer',  'for': ['c', 'cpp'] }
call plug#end()" >> /root/.vimrc
fi
echo '\033[32mFrom the vim command line, run the "PlugInstall" command to install YCM.\033[0m'
echo '\033[32mThen execute "/root/.vim/plugged/YouCompleteMe/install.py"\033[0m'