#!/bin/bash
VIM_VERSION=$(echo `ls /usr/share/vim` | awk '{
string=$0
len=length(string)
for (i=0; i<=len; i++)
{
tmp=substr(string, i, 1)
if (tmp ~ /[0-9]/)
{
str=tmp
str1=(str1 str)
}
}
print str1
}' |  awk '{
for (i=1; i<=length($0); i+=1)
printf substr($0,i,1)" "
print ""}' | awk '{print $1}')
if [ -z "$VIM_VERSION" ]; then
	echo "\033[31mERROR! The VIM version number cannot be detected.\033[0m" && exit 1
else
	echo "\033[32mVim version number is $VIM_VERSION, check OK.\033[0m"
fi

BOOL_1=$(md5sum /etc/vim/vimrc | awk '{print $1}')
BOOL_2=$(md5sum vimrc_global | awk '{print $1}')
if [ "$BOOL_1"x = "$BOOL_2"x ]; then
	echo "\033[32mThe file /etc/vim/vimrc has not been changed.\033[0m"
else
	\cp /etc/vim/vimrc /etc/vim/vimrc.$(date +%Y%m%d_%H%M).bak
	\cp vimrc_global /etc/vim/vimrc
fi

\cp vimrc_hidden /root/.vimrc

[ -d "~/.vim/" ] || mkdir -p ~/.vim/

\cp molokai.vim /usr/share/vim/vim${VIM_VERSION}*/colors/

# Additional configuration
\cp cf jr pw ycm_switch /usr/local/bin/
for SCRIPT in cf jr pw ycm_switch
do
	chmod +x /usr/local/bin/$SCRIPT
done

BOOL_3=$(md5sum /root/.bashrc | awk '{print $1}')
BOOL_4=$(md5sum bashrc_tmpl | awk '{print $1}')
if [ "$BOOL_3"x = "$BOOL_4"x ]; then
	echo "\033[32mThe file bashrc has not been changed.\033[0m"
else
	\cp /root/.bashrc /root/.bashrc.$(date +%Y%m%d_%H%M).bak
	\cp bashrc_tmpl /root/.bashrc
fi
dpkg -l | grep ctags > /dev/null 2>&1
#if [ "$?" != "0" ]; then
#	apt-get install -y ctags  > /dev/null 2>&1
#fi
apt-get install ctags curl git -y > /dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "\033[31mERROR! The required package cannot be installed.\033[0m"
	exit 1
fi

# Install vim-plug
if [ ! -f "/root/.vim/autoload/plug.vim" ]; then
	 curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim > /dev/null 2>&1
fi

[ ! -d "/root/.vim/plugged/nerdtree" ] && \
	echo "\033[32mThe installation is almost complete.\033[0m" && \
	echo '\033[32mFrom the vim command line, run the "PlugInstall" command to install nerdtree plugin.\033[0m' && \
	exit 0
echo "\033[32mThe installation is complete.\033[0m"
