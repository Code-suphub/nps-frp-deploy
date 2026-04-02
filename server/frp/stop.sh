#!/bin/bash

cd "$(dirname "$0")"

MODE="${1:-docker}"

if [ "$MODE" = "binary" ]; then
    # ========== 停止二进制方式运行的服务 ==========
    if [ -f frps.pid ]; then
        PID=$(cat frps.pid)
        if kill -0 $PID 2>/dev/null; then
            echo "停止 FRPS 服务 (PID: $PID)..."
            kill $PID
            # 等待进程结束
            for i in {1..10}; do
                if ! kill -0 $PID 2>/dev/null; then
                    break
                fi
                sleep 1
            done
            # 强制结束如果还在运行
            if kill -0 $PID 2>/dev/null; then
                echo "强制停止..."
                kill -9 $PID 2>/dev/null
            fi
            echo "✓ FRPS 已停止"
        else
            echo "✗ FRPS 未在运行"
        fi
        rm -f frps.pid
    else
        echo "✗ 未找到 PID 文件，尝试查找并停止 frps 进程..."
        pkill -f "./frps" 2>/dev/null && echo "✓ FRPS 已停止" || echo "✗ 未找到运行中的 FRPS 进程"
    fi

else
    # ========== 停止 Docker 方式运行的服务 ==========
    echo "停止 FRPS Docker 服务..."

    if docker compose version &>/dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif docker-compose version &>/dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        echo "✗ 错误: 未找到 docker-compose 命令"
        exit 1
    fi

    if $DOCKER_COMPOSE down; then
        echo "✓ FRPS 已停止"
    else
        echo "✗ 停止失败"
        exit 1
    fi
fi
