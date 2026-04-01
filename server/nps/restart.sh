#!/bin/bash

cd "$(dirname "$0")"

echo "重启 NPS 服务..."

# 重新加载配置到 nps.conf
if [ -f .env ]; then
    set -a
    source .env
    set +a

    # 更新配置文件
    [ -n "$NPS_WEB_USER" ] && sed -i "s/^web_username=.*/web_username=${NPS_WEB_USER}/" conf/nps.conf
    [ -n "$NPS_WEB_PASSWORD" ] && sed -i "s/^web_password=.*/web_password=${NPS_WEB_PASSWORD}/" conf/nps.conf
    [ -n "$NPS_BRIDGE_PORT" ] && sed -i "s/^bridge_port=.*/bridge_port=${NPS_BRIDGE_PORT}/" conf/nps.conf
    [ -n "$NPS_WEB_PORT" ] && sed -i "s/^web_port=.*/web_port=${NPS_WEB_PORT}/" conf/nps.conf

    echo "✓ 配置已更新"
fi

docker compose restart 2>/dev/null || docker-compose restart 2>/dev/null

echo "✓ NPS 已重启"
echo ""
echo "管理界面: http://$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):${NPS_WEB_PORT:-8080}"
