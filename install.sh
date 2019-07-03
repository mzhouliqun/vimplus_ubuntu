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
[ -d "~/.vim/doc/" ] || mkdir -p ~/.vim/doc/
[ -d "~/.vim/plugin/" ] || mkdir -p ~/.vim/plugin/
[ -d "~/.vim/syntax/" ] || mkdir -p ~/.vim/syntax/
[ -d "~/.vim/autoload/" ] || mkdir -p ~/.vim/autoload/
[ -d "~/.vim/lib/" ] || mkdir -p ~/.vim/lib/
[ -d "temp" ] || mkdir temp
unzip -d ./temp/ -o nerdtree-master.zip > /dev/null 2>&1
unzip -d ./temp/taglist_46 -o taglist_46.zip > /dev/null 2>&1
unzip -d ./temp/ -o vimcdoc-2.1.0.zip > /dev/null 2>&1
\cp ./temp/nerdtree-master/doc/* ~/.vim/doc/
\cp ./temp/nerdtree-master/plugin/* ~/.vim/plugin/
\cp ./temp/nerdtree-master/syntax/* ~/.vim/syntax/
\cp -a ./temp/nerdtree-master/nerdtree_plugin/ ~/.vim/
\cp -a ./temp/nerdtree-master/autoload/* ~/.vim/autoload
\cp -a ./temp/nerdtree-master/lib/* ~/.vim/lib
\cp ./temp/taglist_46/doc/* ~/.vim/doc
\cp ./temp/taglist_46/plugin/* ~/.vim/plugin
cd ./temp/vimcdoc-2.1.0/; sh vimcdoc.sh -i > /dev/null 2>&1; cd ../../

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
if [ "$?" != "0" ]; then
	apt-get install -y ctags  > /dev/null 2>&1
fi
rm -fr ./temp > /dev/null 2>&1
echo "\033[32mThe installation is complete.\033[0m"
