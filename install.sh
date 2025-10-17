#!/bin/bash
apt-get install universal-ctags curl git -y > /dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "\033[31mERROR! The required package cannot be installed.\033[0m"
	exit 1
fi

curl -I https://github.com > /dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "\033[31mERROR! Unable to access github.com.\033[0m"
	exit 2
fi

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
	echo "\033[31mERROR! The VIM version number cannot be detected.\033[0m" && exit 3
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
[ -d "~/.vim/doc/" ] || mkdir -p ~/.vim/doc/
[ -d "~/.vim/plugin/" ] || mkdir -p ~/.vim/plugin/
[ -d "temp" ] || mkdir temp
unzip -d ./temp/taglist_46 -o taglist_46.zip > /dev/null 2>&1
\cp ./temp/taglist_46/doc/* ~/.vim/doc
\cp ./temp/taglist_46/plugin/* ~/.vim/plugin
\cp molokai.vim /usr/share/vim/vim${VIM_VERSION}*/colors/

# Additional configuration
\cp cf jr pw ycm nt bk mode_switcher /usr/local/bin/
for SCRIPT in cf jr pw ycm nt bk mode_switcher
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
#dpkg -l | grep ctags > /dev/null 2>&1
#if [ "$?" != "0" ]; then
#	apt-get install -y ctags  > /dev/null 2>&1
#fi

rm -fr ./temp > /dev/null 2>&1

# Install vim-plug
if [ ! -f "/root/.vim/autoload/plug.vim" ]; then
#	 curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	mkdir -p ~/.vim/autoload/
	git clone https://github.com/junegunn/vim-plug.git > /dev/null 2>&1
	\cp vim-plug/plug.vim ~/.vim/autoload/
	rm -fr vim-plug
fi

/usr/bin/bash /usr/local/bin/nt > /dev/null 2>&1
echo "\033[32mThe installation is almost complete.\033[0m"
echo 'Please ignore the above error reporting about the plug-in.
Now type ":PlugInstall" to install the nerdtree plug-in.
when the plug-in installation is complete ,type :qall! to exit vim.' | vim -
echo "\033[32mThe installation is successful.\033[0m"
