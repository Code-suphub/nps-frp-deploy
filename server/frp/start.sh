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

# 生成 frps.toml 配置文件
cat > frps.toml << EOF
bindPort = ${FRPS_BIND_PORT:-7000}
webServer.addr = "0.0.0.0"
webServer.port = ${FRPS_DASHBOARD_PORT:-7500}
webServer.user = "${FRPS_DASHBOARD_USER:-admin}"
webServer.password = "${FRPS_DASHBOARD_PASSWORD:-your_frp_password_here}"
auth.method = "token"
auth.token = "${FRPS_AUTH_TOKEN:-your_frp_token_here}"
allowPorts = [
  { start = ${FRPS_ALLOW_PORTS_START:-7001}, end = ${FRPS_ALLOW_PORTS_END:-7010} }
]
EOF

echo "已生成 frps.toml 配置"

# 启动服务
echo "启动 FRPS 服务..."
docker-compose up -d

echo ""
echo "FRPS Dashboard: http://$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):${FRPS_DASHBOARD_PORT:-7500}"
echo "用户名: ${FRPS_DASHBOARD_USER:-admin}"
echo "密码: ${FRPS_DASHBOARD_PASSWORD:-your_frp_password_here}"
echo "连接 Token: ${FRPS_AUTH_TOKEN:-your_frp_token_here}"
