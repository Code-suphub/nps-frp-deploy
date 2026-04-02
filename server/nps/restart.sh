#!/bin/bash

cd "$(dirname "$0")"

MODE="${1:-docker}"

echo "重启 NPS 服务 (模式: $MODE)..."
echo ""

# 重新加载配置到 nps.conf
if [ -f .env ]; then
    set -a
    source .env
    set +a

    # 更新配置文件
    [ -n "$NPS_WEB_USER" ] && sed -i "s/^web_username\s*=.*/web_username=${NPS_WEB_USER}/" conf/nps.conf
    [ -n "$NPS_WEB_PASSWORD" ] && sed -i "s/^web_password\s*=.*/web_password=${NPS_WEB_PASSWORD}/" conf/nps.conf
    [ -n "$NPS_BRIDGE_PORT" ] && sed -i "s/^bridge_port\s*=.*/bridge_port=${NPS_BRIDGE_PORT}/" conf/nps.conf
    [ -n "$NPS_WEB_PORT" ] && sed -i "s/^web_port\s*=.*/web_port=${NPS_WEB_PORT}/" conf/nps.conf
    [ -n "$NPS_PUBLIC_VKEY" ] && sed -i "s/^public_vkey\s*=.*/public_vkey=${NPS_PUBLIC_VKEY}/" conf/nps.conf

    echo "✓ 配置已更新"
    echo ""
fi

if [ "$MODE" = "binary" ]; then
    # ========== 重启二进制方式运行的服务 ==========
    # 先停止
    if [ -f nps.pid ]; then
        PID=$(cat nps.pid)
        if kill -0 $PID 2>/dev/null; then
            echo "停止当前进程 (PID: $PID)..."
            kill $PID
            for i in {1..10}; do
                if ! kill -0 $PID 2>/dev/null; then
                    break
                fi
                sleep 1
            done
            kill -9 $PID 2>/dev/null
        fi
        rm -f nps.pid
    fi

    # 再启动
    echo "使用二进制方式启动..."
    ./start.sh binary

else
    # ========== 重启 Docker 方式运行的服务 ==========
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
        echo "  1. 检查 Docker 是否安装: docker --version"
        echo "  2. 安装 compose 插件: apt-get install -y docker-compose-plugin"
        echo "  3. 使用二进制方式启动: ./restart.sh binary"
        exit 1
    fi

    if $DOCKER_COMPOSE restart; then
        echo "✓ NPS 已重启"
        echo ""
        echo "【访问信息】"
        echo "  管理界面: http://$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):${NPS_WEB_PORT:-8080}"
    else
        echo ""
        echo "✗ 重启失败"
        echo ""
        echo "【排查指引】"
        echo "  1. 检查服务是否已启动: $DOCKER_COMPOSE ps"
        echo "  2. 查看错误日志: $DOCKER_COMPOSE logs"
        echo "  3. 尝试使用二进制方式: ./restart.sh binary"
        exit 1
    fi
fi
