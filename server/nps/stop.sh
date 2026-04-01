#!/bin/bash

echo "停止 NPS 服务..."
cd "$(dirname "$0")"
docker compose down 2>/dev/null || docker-compose down 2>/dev/null

echo "✓ NPS 已停止"
