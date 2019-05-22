#!/bin/bash
#apt purge --auto-remove vim
apt-get update
apt-get install gcc g++ makev -y
apt-get install vim vim-gtk3 vim-tiny neovim vim-athena vim-gtk vim-nox -y
apt-get install python-pip curl git libncurses5-dev python-dev python3-dev build-essential cmake clang libclang-dev -y
# 安装vim-plug插件管理器
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
sed -i '/\" YouCompleteMe/,$s/^\"//' /root/.vimrc
echo '\033[32mFrom the vim command line, run the "PlugInstall" command to install YCM.\033[0m'
echo '\033[32mIf installation fails, execute "/root/.vim/plugged/YouCompleteMe/install.py to reinstall the YCM plug-in"\033[0m'
