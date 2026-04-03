#!/bin/bash

# 默认值
DEFAULT_IP="10.7.236.189"
DEFAULT_PORT="7890"

# 初始化变量
PROXY_IP="$DEFAULT_IP"
PROXY_PORT="$DEFAULT_PORT"
DISABLE_PROXY=0

# 解析命令行参数
while [ $# -gt 0 ]; do
    case "$1" in
        --ip)
            PROXY_IP="$2"
            shift 2
            ;;
        --port)
            PROXY_PORT="$2"
            shift 2
            ;;
        --disable)
            DISABLE_PROXY=1
            shift 1
            ;;
        *)
            echo "用法: $0 [--ip <IP>] [--port <PORT>] [--disable]"
            echo "示例: $0 --ip 192.168.1.1 --port 8080"
            echo "      $0 --disable"
            exit 1
            ;;
    esac
done

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
    echo "错误: 请以 root 权限运行此脚本 (使用 sudo)"
    exit 1
fi

# 目标文件
BASHRC_FILE="/root/.bashrc"

# 检查文件是否存在
if [ ! -f "$BASHRC_FILE" ]; then
    echo "错误: $BASHRC_FILE 不存在"
    exit 1
fi

# 检查文件是否可写
if [ ! -w "$BASHRC_FILE" ]; then
    echo "错误: $BASHRC_FILE 不可写，请检查权限"
    ls -l "$BASHRC_FILE"
    exit 1
fi

# 处理 --disable 参数
if [ "$DISABLE_PROXY" -eq 1 ]; then
    if grep -E "http_proxy=|https_proxy=|all_proxy=|no_proxy=" "$BASHRC_FILE" >/dev/null 2>&1; then
        echo "检测到 $BASHRC_FILE 中存在代理配置，正在注释配置..."
        # 创建临时文件
        TEMP_FILE=$(mktemp)
        # 注释代理配置行
        sed '/# Proxy settings added by set_proxy.sh/,/no_proxy=/s/^/#/' "$BASHRC_FILE" > "$TEMP_FILE"
        # 替换原文件
        if cp "$TEMP_FILE" "$BASHRC_FILE"; then
            rm "$TEMP_FILE"
            echo "代理配置已成功注释"
            echo "请运行以下命令使更改立即生效："
            echo "unset http_proxy https_proxy all_proxy no_proxy"
            echo "或重新打开终端以应用更改。"
            exit 0
        else
            rm "$TEMP_FILE"
            echo "错误: 无法注释配置，请检查 $BASHRC_FILE 权限"
            exit 1
        fi
    else
        echo "未检测到 $BASHRC_FILE 中的代理配置，无需注释"
        exit 0
    fi
fi

# 代理配置内容（去除多余空行）
PROXY_CONFIG="# Proxy settings added by set_proxy.sh
export http_proxy=\"http://$PROXY_IP:$PROXY_PORT\"
export https_proxy=\"http://$PROXY_IP:$PROXY_PORT\"
export all_proxy=\"http://$PROXY_IP:$PROXY_PORT\"
export no_proxy=\"localhost,127.0.0.1,::1,192.168.*,10.*,172.24.*,172.16.*\""

## 代理配置内容（去除多余空行）
#PROXY_CONFIG="# Proxy settings added by set_proxy.sh
#export http_proxy=\"socks5://127.0.0.1:2118\"
#export https_proxy=\"socks5://127.0.0.1:2118\"
#export all_proxy=\"socks5://127.0.0.1:1080\"
#export no_proxy=\"localhost,127.0.0.1,::1,192.168.*,10.*,172.24.*,172.16.*\""

# 检查是否已存在代理配置并删除
if grep -E "http_proxy=|https_proxy=|all_proxy=|no_proxy=" "$BASHRC_FILE" >/dev/null 2>&1; then
    echo "检测到 $BASHRC_FILE 中已存在代理配置，正在删除旧配置..."
    # 创建临时文件
    TEMP_FILE=$(mktemp)
    # 删除包含代理设置的行（包括脚本的注释）
    sed '/# Proxy settings added by set_proxy.sh/,/no_proxy=/d' "$BASHRC_FILE" > "$TEMP_FILE"
    # 移除尾随空行
    sed -i '/^$/d' "$TEMP_FILE"
    # 替换原文件
    if cp "$TEMP_FILE" "$BASHRC_FILE"; then
        rm "$TEMP_FILE"
        echo "旧代理配置已删除"
    else
        rm "$TEMP_FILE"
        echo "错误: 无法删除旧配置，请检查 $BASHRC_FILE 权限"
        exit 1
    fi
else
    echo "未检测到现有代理配置，将直接添加新配置"
fi

# 追加代理配置到 .bashrc，使用 printf 避免额外换行
printf "%s\n" "$PROXY_CONFIG" >> "$BASHRC_FILE"
if [ $? -eq 0 ]; then
    echo "成功将代理配置 (IP: $PROXY_IP, Port: $PROXY_PORT) 添加到 $BASHRC_FILE"
else
    echo "错误: 无法写入 $BASHRC_FILE"
    echo "请检查以下内容："
    echo "- 文件权限: ls -l $BASHRC_FILE"
    echo "- 磁盘空间: df -h"
    echo "- 文件系统是否只读: mount | grep ' / '"
    exit 1
fi

# 提示用户使配置生效
echo "请运行以下命令使配置立即生效："
echo "source $BASHRC_FILE"
echo "或重新打开终端以应用更改。"
