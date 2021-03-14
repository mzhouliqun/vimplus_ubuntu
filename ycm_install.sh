#!/bin/bash
#apt purge --auto-remove vim
apt-get update
apt-get install gcc g++ make cmake -y
apt-get install vim vim-gtk3 vim-tiny neovim vim-athena vim-gtk vim-nox -y
apt-get install curl git libncurses5-dev python-dev python3-dev build-essential cmake clang libclang-dev python3-pip -y
apt-get install python-dev-is-python2 -y

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
echo '\033[32mFrom the vim command line, run the "PlugInstall" command to install YCM.\033[0m'
