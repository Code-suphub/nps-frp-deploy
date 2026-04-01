#!/bin/bash

cd "$(dirname "$0")"

source .env 2>/dev/null

echo "停止 NPS 客户端..."
docker compose down 2>/dev/null || docker-compose down 2>/dev/null

echo "✓ 已停止"
