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

cp /etc/vim/vimrc /etc/vim/vimrc.$(date +%Y%m%d).bak
\cp vimrc_global /etc/vim/vimrc

cat /etc/vim/vimrc | grep autocmd | grep formatoptions > /dev/null 2>&1
if [ "$?" != "0" ]; then
	echo 'autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o' >> /etc/vim/vimrc
fi

cp vimrc_hidden /root/.vimrc

[ -d "~/.vim/" ] || mkdir -p ~/.vim/
[ -d "~/.vim/doc/" ] || mkdir -p ~/.vim/doc/
[ -d "~/.vim/plugin/" ] || mkdir -p ~/.vim/plugin/
[ -d "~/.vim/syntax/" ] || mkdir -p ~/.vim/syntax/
[ -d "~/.vim/autoload/" ] || mkdir -p ~/.vim/autoload/
[ -d "~/.vim/lib/" ] || mkdir -p ~/.vim/lib/
[ -d "temp" ] || mkdir temp
unzip -d ./temp/ -o nerdtree-5.0.0.zip > /dev/null 2>&1
unzip -d ./temp/taglist_46 -o taglist_46.zip > /dev/null 2>&1
unzip -d ./temp/ -o vimcdoc-2.1.0.zip > /dev/null 2>&1
cp ./temp/nerdtree-5.0.0/doc/* ~/.vim/doc/
cp ./temp/nerdtree-5.0.0/plugin/* ~/.vim/plugin/
cp ./temp/nerdtree-5.0.0/syntax/* ~/.vim/syntax/
cp -a ./temp/nerdtree-5.0.0/nerdtree_plugin/ ~/.vim/
cp -a ./temp/nerdtree-5.0.0/autoload/* ~/.vim/autoload
cp -a ./temp/nerdtree-5.0.0/lib/* ~/.vim/lib
cp ./temp/taglist_46/doc/* ~/.vim/doc
cp ./temp/taglist_46/plugin/* ~/.vim/plugin
cd ./temp/vimcdoc-2.1.0/; sh vimcdoc.sh -i > /dev/null 2>&1; cd ../../

cp molokai.vim /usr/share/vim/vim${VIM_VERSION}*/colors/

# Additional configuration
cp cf jr pw rg /usr/local/bin/
chmod +x /usr/local/bin/*

BOOL_1=$(md5sum /root/.bashrc | awk '{print $1}')
BOOL_2=$(md5sum bashrc_tmpl | awk '{print $1}')
if [ "$BOOL_1"x = "$BOOL_2"x ]; then
	echo "\033[32mThe file bashrc has not changed.\033[0m"
else
	cp /root/.bashrc /root/.bashrc.$(date +%Y%m%d_%H%M).bak
	cp bashrc_tmpl /root/.bashrc
fi
dpkg -l | grep ctags > /dev/null 2>&1
if [ "$?" != "0" ]; then
	apt-get install -y ctags  > /dev/null 2>&1
fi
rm -fr ./temp > /dev/null 2>&1
echo "\033[32mThe installation is complete.\033[0m"