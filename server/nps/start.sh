#!/bin/bash

cd "$(dirname "$0")"

# 加载环境变量
if [ -f .env ]; then
    set -a
    source .env
    set +a
    echo "已加载 .env 配置"
else
    echo "警告: .env 文件不存在，使用默认配置"
fi

# 更新配置文件中的参数
if [ -n "$NPS_WEB_PASSWORD" ]; then
    sed -i "s/^web_password\s*=.*/web_password=$NPS_WEB_PASSWORD/" conf/nps.conf
fi

if [ -n "$NPS_WEB_USER" ]; then
    sed -i "s/^web_username\s*=.*/web_username=$NPS_WEB_USER/" conf/nps.conf
fi

if [ -n "$NPS_BRIDGE_PORT" ]; then
    sed -i "s/^bridge_port\s*=.*/bridge_port=$NPS_BRIDGE_PORT/" conf/nps.conf
fi

if [ -n "$NPS_WEB_PORT" ]; then
    sed -i "s/^web_port\s*=.*/web_port=$NPS_WEB_PORT/" conf/nps.conf
fi

if [ -n "$NPS_PUBLIC_VKEY" ]; then
    sed -i "s/^public_vkey\s*=.*/public_vkey=$NPS_PUBLIC_VKEY/" conf/nps.conf
fi

# 选择启动方式
MODE="${1:-docker}"

if [ "$MODE" = "binary" ]; then
    # ========== 二进制方式启动 ==========
    echo ""
    echo "使用二进制方式启动 NPS..."

    # 检测操作系统和架构
    if [ -z "$ARCH" ] || [ "$ARCH" = "auto" ]; then
        # 检测操作系统
        OS=$(uname -s)
        case $OS in
            Linux)
                OS_TYPE="linux"
                ;;
            Darwin)
                OS_TYPE="darwin"
                ;;
            *)
                echo "❌ 不支持的操作系统: $OS"
                echo "   请手动设置 ARCH 变量，格式: {os}_{arch}"
                echo "   可选: linux_amd64, linux_arm64, darwin_amd64, darwin_arm64"
                exit 1
                ;;
        esac

        # 检测架构
        case $(uname -m) in
            x86_64|amd64)
                ARCH_TYPE="amd64"
                ;;
            aarch64|arm64)
                ARCH_TYPE="arm64"
                ;;
            armv7l)
                ARCH_TYPE="arm_v7"
                ;;
            *)
                echo "❌ 无法自动检测架构: $(uname -m)"
                echo "   请手动设置 ARCH 变量，格式: {os}_{arch}"
                echo "   可选: linux_amd64, linux_arm64, darwin_amd64, darwin_arm64"
                exit 1
                ;;
        esac

        ARCH="${OS_TYPE}_${ARCH_TYPE}"
        echo "✓ 自动检测到系统: $OS ($ARCH)"
    fi

    # 检查二进制文件
    NPS_BINARY="./nps"
    if [ ! -f "$NPS_BINARY" ]; then
        echo "未找到 NPS 二进制文件，开始下载..."

        # 从 GitHub 下载最新版本
        DOWNLOAD_URL="https://github.com/ehang-io/nps/releases/download/v0.26.10/${ARCH}_server.tar.gz"

        echo "下载地址: $DOWNLOAD_URL"
        if ! curl -L -o nps.tar.gz "$DOWNLOAD_URL"; then
            echo ""
            echo "✗ 下载失败"
            echo ""
            echo "【排查指引】"
            echo "  1. 检查网络连接: ping github.com"
            echo "  2. 手动下载: https://github.com/ehang-io/nps/releases"
            echo "  3. 下载后解压到当前目录: tar -xzf ${ARCH}_server.tar.gz"
            exit 1
        fi

        echo "解压中..."
        tar -xzf nps.tar.gz
        rm -f nps.tar.gz

        # 设置可执行权限
        chmod +x nps

        echo "✓ 下载完成"
    fi

    # 检查是否已在运行
    if [ -f nps.pid ] && kill -0 $(cat nps.pid) 2>/dev/null; then
        echo "✗ NPS 已在运行 (PID: $(cat nps.pid))"
        echo "   请先执行 ./stop.sh 停止，或使用 ./restart.sh 重启"
        exit 1
    fi

    echo ""
    echo "启动 NPS 服务..."

    # 以后台方式运行
    nohup ./nps > nps.log 2>&1 &

    PID=$!
    echo $PID > nps.pid

    # 等待检查是否启动成功
    sleep 2
    if kill -0 $PID 2>/dev/null; then
        echo ""
        echo "✓ NPS 启动成功 (PID: $PID)"
    else
        echo ""
        echo "✗ 启动失败，请查看日志: tail -f nps.log"
        rm -f nps.pid
        exit 1
    fi

    echo ""
    echo "【访问信息】"
    echo "  管理界面: http://$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):${NPS_WEB_PORT:-8080}"
    echo "  用户名: ${NPS_WEB_USER:-admin}"
    echo "  密码: ${NPS_WEB_PASSWORD:-your_nps_password_here}"
    echo ""
    echo "【管理命令】"
    echo "  查看日志: tail -f nps.log"
    echo "  停止服务: ./stop.sh binary"
    echo "  重启服务: ./restart.sh binary"

else
    # ========== Docker 方式启动 ==========
    echo ""
    echo "使用 Docker 方式启动 NPS..."

    # 检测 docker compose 命令
    if docker compose version &>/dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif docker-compose version &>/dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        echo ""
        echo "✗ 错误: 未找到 docker-compose 或 docker compose 命令"
        echo ""
        echo "【排查指引】"
        echo "  1. 检查 Docker 是否安装:"
        echo "     docker --version"
        echo ""
        echo "  2. 如果已安装 Docker 但无 compose 插件:"
        echo "     # 安装 docker-compose-plugin"
        echo "     apt-get update && apt-get install -y docker-compose-plugin"
        echo ""
        echo "  3. 或使用独立 docker-compose:"
        echo "     curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        echo "     chmod +x /usr/local/bin/docker-compose"
        echo ""
        echo "  4. 使用二进制方式启动:"
        echo "     ./start.sh binary"
        echo ""
        exit 1
    fi

    # 尝试启动
    if ! $DOCKER_COMPOSE up -d; then
        echo ""
        echo "✗ 启动失败"
        echo ""
        echo "【排查指引】"
        echo "  1. 检查 Docker 服务是否运行:"
        echo "     systemctl status docker"
        echo ""
        echo "  2. 检查端口是否被占用:"
        echo "     netstat -tlnp | grep -E '(${NPS_WEB_PORT:-8080}|${NPS_BRIDGE_PORT:-8024})'"
        echo ""
        echo "  3. 查看详细错误日志:"
        echo "     $DOCKER_COMPOSE logs"
        echo ""
        echo "  4. 检查配置文件是否正确:"
        echo "     cat conf/nps.conf | head -20"
        echo ""
        echo "  5. 尝试使用二进制方式启动:"
        echo "     ./start.sh binary"
        echo ""
        exit 1
    fi

    echo ""
    echo "✓ NPS 启动成功"
    echo ""
    echo "【访问信息】"
    echo "  管理界面: http://$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):${NPS_WEB_PORT:-8080}"
    echo "  用户名: ${NPS_WEB_USER:-admin}"
    echo "  密码: ${NPS_WEB_PASSWORD:-your_nps_password_here}"
    echo ""
    echo "【管理命令】"
    echo "  查看日志: $DOCKER_COMPOSE logs -f"
    echo "  停止服务: ./stop.sh"
    echo "  重启服务: ./restart.sh"
fi

echo ""
