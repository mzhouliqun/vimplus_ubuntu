#!/bin/bash
#apt purge --auto-remove vim
apt-get update
apt-get install gcc g++ make cmake -y
apt-get install vim vim-gtk3 vim-tiny neovim vim-athena vim-gtk vim-nox -y
apt-get install curl git libncurses5-dev python3-dev build-essential cmake clang libclang-dev python3-pip -y

FILENAME=/root/.vimrc
STRING='\" YouCompleteMe'
turnon() {
	sed -i '/Valloric\/YouCompleteMe/s/^\"//' $1
}

turnoff() {
	sed -i '/Valloric\/YouCompleteMe/s/^.*$/\"&/' $1
}

str=$(cat $FILENAME | grep Valloric/YouCompleteMe | awk '{print substr($1,1,1)}')
if [ "$str" != "\"" ]
then
	turnoff $FILENAME
fi

turnon $FILENAME
echo '\033[32mExecute the ':PlugInstall' command in Vim command-line mode to install the YCM plugin, ignore the error message and exit Vim after execution.\033[0m'
echo '\033[32mThen execute the following command on the shell command line:\033[0m'
echo '\033[32mcd /root/.vim/plugged/YouCompleteMe\033[0m'
echo '\033[32mpython3 install.py --clang-completer --force-sudo\033[0m'
