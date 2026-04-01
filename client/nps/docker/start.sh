#!/bin/bash

cd "$(dirname "$0")"

# 检查 .env 是否已配置
if [ -f .env ]; then
    source .env
fi

if [ "$NPS_SERVER" = "你的服务器IP:8024" ] || [ -z "$NPS_SERVER" ]; then
    echo "❌ 错误: 请先编辑 .env 文件，配置 NPS_SERVER"
    exit 1
fi

if [ "$NPS_VKEY" = "your_vkey_here" ] || [ -z "$NPS_VKEY" ]; then
    echo "❌ 错误: 请先编辑 .env 文件，配置 NPS_VKEY"
    echo "提示: 从 NPS Web 管理界面的「客户端」页面获取 vkey"
    exit 1
fi

echo "启动 NPS 客户端..."
echo "服务器: $NPS_SERVER"
echo "VKey: ${NPS_VKEY:0:4}****"

docker compose up -d 2>/dev/null || docker-compose up -d

echo ""
echo "✓ NPS 客户端已启动"
echo ""
echo "查看日志: docker logs -f ${CONTAINER_NAME:-npc}"
