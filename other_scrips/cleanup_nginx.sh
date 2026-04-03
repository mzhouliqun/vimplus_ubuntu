#!/bin/bash

# Nginx 完全清理脚本
# 用于清理之前安装的nginx文件和服务配置

set -e

echo "开始清理 Nginx 安装..."

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 用户运行此脚本"
    exit 1
fi

# 定义颜色输出（简化版本）
log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# 停止nginx服务
log_info "停止 Nginx 服务..."
systemctl stop nginx 2>/dev/null || service nginx stop 2>/dev/null || pkill nginx 2>/dev/null || true
sleep 2

# 确保nginx进程完全停止
if pgrep nginx >/dev/null; then
    log_warn "强制停止 Nginx 进程..."
    pkill -9 nginx 2>/dev/null || true
    sleep 1
fi

# 禁用服务
log_info "禁用服务..."
systemctl disable nginx 2>/dev/null || true
update-rc.d nginx remove 2>/dev/null || true

# 删除系统服务文件
log_info "删除服务文件..."
rm -f /etc/init.d/nginx
rm -f /lib/systemd/system/nginx.service
rm -f /usr/lib/systemd/system/nginx.service

# 重新加载systemd
systemctl daemon-reload 2>/dev/null || true

# 删除nginx二进制文件
log_info "删除nginx二进制文件..."
rm -f /usr/sbin/nginx
rm -f /usr/local/sbin/nginx
rm -f /sbin/nginx

# 删除配置文件
log_info "删除配置文件..."
if [ -d "/etc/nginx" ]; then
    log_warn "备份 /etc/nginx 到 /etc/nginx.backup.$(date +%Y%m%d%H%M%S)"
    cp -r /etc/nginx /etc/nginx.backup.$(date +%Y%m%d%H%M%S) 2>/dev/null || true
fi
rm -rf /etc/nginx

# 删除安装目录
log_info "删除安装目录..."
rm -rf /usr/share/nginx
rm -rf /usr/lib/nginx

# 删除日志和缓存目录（可选，保留数据）
echo "是否删除日志和缓存目录？(y/N): "
read REPLY
if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    log_info "删除日志和缓存目录..."
    rm -rf /var/log/nginx
    rm -rf /var/cache/nginx
    rm -rf /var/lib/nginx
else
    log_info "保留日志和缓存目录"
fi

# 删除运行时文件
log_info "删除运行时文件..."
rm -f /run/nginx.pid
rm -f /run/nginx.pid.oldbin
rm -f /var/lock/nginx.lock

# 删除nginx用户（可选）
echo "是否删除nginx用户？(y/N): "
read REPLY
if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    log_info "删除nginx用户..."
    userdel nginx 2>/dev/null || true
    groupdel nginx 2>/dev/null || true
else
    log_info "保留nginx用户"
fi

# 清理编译文件（如果在源码目录运行）
if [ -f "Makefile" ]; then
    log_info "清理编译文件..."
    make clean 2>/dev/null || true
    make distclean 2>/dev/null || true
fi

# 删除源码编译的中间文件
log_info "清理编译中间文件..."
rm -rf objs 2>/dev/null || true
rm -f Makefile 2>/dev/null || true

# 检查是否还有nginx进程或文件残留
log_info "检查残留..."
if pgrep nginx >/dev/null; then
    log_warn "发现残留的nginx进程:"
    pgrep nginx
    echo "是否强制杀死这些进程？(y/N): "
    read REPLY
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        pkill -9 nginx
    fi
fi

# 验证清理结果
log_info "验证清理结果..."
echo "=== 检查nginx二进制文件 ==="
if which nginx >/dev/null 2>&1; then
    log_warn "发现nginx二进制文件"
else
    log_info "未发现nginx二进制文件"
fi

echo "=== 检查nginx进程 ==="
if pgrep nginx >/dev/null; then
    log_warn "发现nginx进程"
else
    log_info "未发现nginx进程"
fi

echo "=== 检查nginx服务 ==="
if systemctl list-unit-files | grep nginx >/dev/null 2>&1; then
    log_warn "发现nginx服务"
else
    log_info "未发现nginx服务"
fi

log_info "清理完成！现在可以重新安装 Nginx 了"

