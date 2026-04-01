#!/bin/bash

cd "$(dirname "$0")"

if [ -f npc.pid ]; then
    PID=$(cat npc.pid)
    if kill -0 "$PID" 2>/dev/null; then
        echo "停止 NPS 客户端 (PID: $PID)..."
        kill "$PID"
        sleep 1
        if kill -0 "$PID" 2>/dev/null; then
            echo "强制终止..."
            kill -9 "$PID"
        fi
        echo "✓ 已停止"
    else
        echo "进程不存在"
    fi
    rm -f npc.pid
else
    echo "未找到 PID 文件，尝试查找进程..."
    pkill -f "npc -server=" 2>/dev/null && echo "✓ 已停止" || echo "未找到运行中的进程"
fi
