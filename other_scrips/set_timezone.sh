#!/bin/bash

#修改时区：
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#修改24小时时间格式：
echo '/etc/default/locale' >> /etc/default/locale
