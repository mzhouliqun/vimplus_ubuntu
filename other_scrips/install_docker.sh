#!/bin/bash

# Docker 一键安装脚本 for Ubuntu 24.04
# 功能：安装 Docker CE、Docker Compose 插件，并配置用户权限
# 作者：AI Assistant
# 日期：2026

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_warn "当前以 root 用户运行，将跳过用户组配置步骤"
        IS_ROOT=true
    else
        IS_ROOT=false
    fi
}

# 卸载旧版本
remove_old_versions() {
    log_info "正在清理可能存在的旧版本 Docker..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        if dpkg -l | grep -q $pkg; then
            log_info "移除 $pkg"
            sudo apt-get remove -y $pkg 2>/dev/null || true
        fi
    done
    log_info "旧版本清理完成"
}

# 安装依赖
install_dependencies() {
    log_info "正在安装必要的依赖包..."
    sudo apt-get update -qq
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    log_info "依赖包安装完成"
}

# 添加 Docker 官方 GPG 密钥和仓库
add_docker_repo() {
    log_info "正在添加 Docker 官方仓库..."

    # 创建密钥目录
    sudo install -m 0755 -d /etc/apt/keyrings

    # 下载并安装 GPG 密钥
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # 添加仓库（支持国内镜像加速）
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    log_info "Docker 官方仓库添加完成"
}

# 安装 Docker 引擎
install_docker() {
    log_info "正在安装 Docker 引擎..."

    # 更新包索引
    sudo apt-get update -qq

    # 安装 Docker 及相关组件
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    log_info "Docker 引擎安装完成"
}

# 启动并启用 Docker 服务
start_docker_service() {
    log_info "正在启动 Docker 服务..."

    # 启动 Docker
    sudo systemctl start docker

    # 设置开机自启
    sudo systemctl enable docker

    # 检查服务状态
    if systemctl is-active --quiet docker; then
        log_info "Docker 服务已成功启动并设置为开机自启"
    else
        log_error "Docker 服务启动失败"
        exit 1
    fi
}

# 配置用户权限（非 root 用户）
configure_user_permissions() {
    if [ "$IS_ROOT" = false ]; then
        log_info "正在配置用户权限..."

        # 将当前用户添加到 docker 组
        sudo usermod -aG docker $USER
        log_info "已将用户 $USER 添加到 docker 组"
        log_warn "请注销并重新登录，或运行 'newgrp docker' 使权限生效"
    else
        log_warn "以 root 用户运行，跳过用户权限配置"
    fi
}

# 验证安装
verify_installation() {
    log_info "正在验证 Docker 安装..."

    # 检查 Docker 版本
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_info "Docker 版本: $DOCKER_VERSION"
    else
        log_error "Docker 命令未找到，安装可能失败"
        exit 1
    fi

    # 检查 Docker Compose 版本
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        log_info "Docker Compose 版本: $COMPOSE_VERSION"
    else
        log_warn "Docker Compose 命令未找到"
    fi

    # 测试运行 hello-world 容器
    log_info "正在运行测试容器..."
    if sudo docker run --rm hello-world | grep -q "Hello from Docker!"; then
        log_info "测试容器运行成功！Docker 安装正常"
    else
        log_error "测试容器运行失败"
        exit 1
    fi
}

# 配置国内镜像加速（可选）
configure_mirror() {
    read -p "是否配置国内镜像加速？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "正在配置国内镜像加速..."

        sudo mkdir -p /etc/docker
        cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

        # 重启 Docker 使配置生效
        sudo systemctl restart docker
        log_info "镜像加速配置完成并已重启 Docker"
    else
        log_info "跳过镜像加速配置"
    fi
}

# 显示安装总结
show_summary() {
    echo
    log_info "=========================================="
    log_info "Docker 安装完成！"
    log_info "=========================================="

    if [ "$IS_ROOT" = false ]; then
        echo
        log_warn "重要提示："
        log_warn "1. 请注销当前用户并重新登录，或运行 'newgrp docker'"
        log_warn "2. 之后运行 docker 命令就无需 sudo 了"
        echo
    fi

    log_info "常用命令："
    echo "  docker --version          # 查看 Docker 版本"
    echo "  docker compose version    # 查看 Docker Compose 版本"
    echo "  docker ps                 # 查看运行中的容器"
    echo "  docker images             # 查看本地镜像"
    echo "  systemctl status docker   # 查看 Docker 服务状态"
    echo
    log_info "如需卸载 Docker，请运行："
    echo "  sudo apt-get purge docker-ce docker-ce-cli containerd.io"
    echo "  sudo rm -rf /var/lib/docker"
}

# 主函数
main() {
    echo "=========================================="
    echo "Docker 一键安装脚本 for Ubuntu 24.04"
    echo "=========================================="
    echo

    # 检查系统版本
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        log_warn "此脚本专为 Ubuntu 24.04 设计，当前系统可能不是 Ubuntu 24.04"
        read -p "是否继续安装？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # 执行安装步骤
    check_root
    remove_old_versions
    install_dependencies
    add_docker_repo
    install_docker
    start_docker_service
    verify_installation
    configure_user_permissions
    configure_mirror
    show_summary
}

# 运行主函数
main
