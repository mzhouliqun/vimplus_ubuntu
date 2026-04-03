#!/bin/bash

# Ubuntu 20.04 rc.local 开机自启设置脚本
# 使用方法: sudo bash setup_rc_local.sh

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用sudo或以root用户运行此脚本"
    exit 1
fi

echo "开始配置rc.local开机自启..."

# 1. 检查并备份原始的rc-local.service文件
RC_SERVICE_SRC="/lib/systemd/system/rc-local.service"
RC_SERVICE_DST="/etc/systemd/system/rc-local.service"

if [ -f "$RC_SERVICE_SRC" ]; then
    echo "找到原始服务文件: $RC_SERVICE_SRC"

    # 备份原始文件（如果目标文件不存在）
    if [ ! -f "$RC_SERVICE_DST" ]; then
        cp "$RC_SERVICE_SRC" "$RC_SERVICE_DST"
        echo "已复制服务文件到: $RC_SERVICE_DST"
    else
        echo "目标文件已存在，将进行备份..."
        cp "$RC_SERVICE_DST" "${RC_SERVICE_DST}.backup.$(date +%Y%m%d%H%M%S)"
    fi
else
    echo "错误: 未找到原始服务文件 $RC_SERVICE_SRC"
    exit 1
fi

# 2. 检查并添加[Install]段到服务文件
if grep -q "\[Install\]" "$RC_SERVICE_DST"; then
    echo "服务文件已包含[Install]段，跳过添加"
else
    echo "正在添加[Install]段到服务文件..."
    cat >> "$RC_SERVICE_DST" << EOF

[Install]
WantedBy=multi-user.target
Alias=rc-local.service
EOF
    echo "[Install]段已添加"
fi

# 3. 创建/etc/rc.local文件（如果不存在）
RC_LOCAL_FILE="/etc/rc.local"
if [ ! -f "$RC_LOCAL_FILE" ]; then
    echo "创建 $RC_LOCAL_FILE 文件..."
    touch "$RC_LOCAL_FILE"
else
    echo "$RC_LOCAL_FILE 已存在，将进行备份..."
    cp "$RC_LOCAL_FILE" "${RC_LOCAL_FILE}.backup.$(date +%Y%m%d%H%M%S)"
fi

# 4. 写入默认的rc.local内容（包含测试脚本）
cat > "$RC_LOCAL_FILE" << 'EOF'
#!/bin/bash

# 在这里添加您需要在开机时执行的命令
# 例如：

echo "看到这行字，说明添加自启动脚本成功。" > /usr/local/test.log

# 可以添加更多命令
# /path/to/your/script.sh
# command --option

exit 0
EOF
echo "已写入默认内容到 $RC_LOCAL_FILE"

# 5. 设置rc.local可执行权限
chmod +x "$RC_LOCAL_FILE"
echo "已设置 $RC_LOCAL_FILE 为可执行权限"

# 6. 重新加载systemd配置
echo "重新加载systemd配置..."
systemctl daemon-reload

# 7. 启用并启动rc-local服务
echo "启用rc-local服务开机自启..."
systemctl enable rc-local.service

echo "启动rc-local服务..."
systemctl start rc-local.service

# 8. 检查服务状态
echo "检查服务状态..."
sleep 2
systemctl status rc-local.service --no-pager

# 9. 验证测试脚本是否执行
echo "验证测试结果..."
if [ -f "/usr/local/test.log" ]; then
    echo "测试成功！test.log 内容："
    cat "/usr/local/test.log"
else
    echo "警告: /usr/local/test.log 未生成，请检查服务状态"
fi

echo ""
echo "rc.local配置完成！"
echo "您现在可以编辑 /etc/rc.local 文件，添加您需要的开机自启命令。"
echo "注意事项："
echo "1. 确保命令在exit 0之前"
echo "2. 脚本需要以 #!/bin/bash 开头"
echo "3. 添加完命令后不需要重启服务，重启系统即可生效"
