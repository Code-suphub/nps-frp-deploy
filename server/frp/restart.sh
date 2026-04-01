#!/bin/bash

cd "$(dirname "$0")"

echo "重启 FRPS 服务..."

# 重新生成 frps.toml
if [ -f .env ]; then
    set -a
    source .env
    set +a

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

    echo "✓ 配置已更新"
fi

docker compose restart 2>/dev/null || docker-compose restart 2>/dev/null

echo "✓ FRPS 已重启"
echo ""
echo "Dashboard: http://$(curl -s ifconfig.me 2>/dev/null || echo '你的服务器IP'):${FRPS_DASHBOARD_PORT:-7500}"
