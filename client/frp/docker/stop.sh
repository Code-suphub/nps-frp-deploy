#!/bin/bash

cd "$(dirname "$0")"

source .env 2>/dev/null

echo "停止 FRP 客户端..."
docker compose down 2>/dev/null || docker-compose down 2>/dev/null
docker stop ${CONTAINER_NAME:-frpc} 2>/dev/null
docker rm ${CONTAINER_NAME:-frpc} 2>/dev/null

echo "✓ 已停止"
