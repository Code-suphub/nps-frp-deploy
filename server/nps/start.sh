#!/bin/bash

# 加载环境变量
if [ -f .env ]; then
    set -a
    source .env
    set +a
    echo "已加载 .env 配置"
else
    echo "警告: .env 文件不存在，使用默认配置"
fi

# 更新配置文件中的密码
if [ -n "$NPS_WEB_PASSWORD" ]; then
    sed -i "s/web_password=.*/web_password=$NPS_WEB_PASSWORD/" conf/nps.conf
fi

if [ -n "$NPS_WEB_USER" ]; then
    sed -i "s/web_username=.*/web_username=$NPS_WEB_USER/" conf/nps.conf
fi

if [ -n "$NPS_BRIDGE_PORT" ]; then
    sed -i "s/bridge_port=.*/bridge_port=$NPS_BRIDGE_PORT/" conf/nps.conf
fi

if [ -n "$NPS_WEB_PORT" ]; then
    sed -i "s/web_port=.*/web_port=$NPS_WEB_PORT/" conf/nps.conf
fi

# 启动服务
echo "启动 NPS 服务..."
docker-compose up -d

echo ""
echo "NPS 管理界面: http://$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):${NPS_WEB_PORT:-8080}"
echo "用户名: ${NPS_WEB_USER:-admin}"
echo "密码: ${NPS_WEB_PASSWORD:-your_nps_password_here}"
