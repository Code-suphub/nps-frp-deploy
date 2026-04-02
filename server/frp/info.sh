#!/bin/bash

cd "$(dirname "$0")"

echo "================================"
echo "       FRPS 服务信息"
echo "================================"
echo ""

# 获取服务器 IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo '你的服务器IP')

# 从配置文件读取参数
if [ -f frps.toml ]; then
    BIND_PORT=$(grep 'bindPort' frps.toml | grep -oP '\d+' | head -1)
    DASHBOARD_PORT=$(grep 'webServer.port' frps.toml | grep -oP '\d+' | head -1)
    DASHBOARD_USER=$(grep 'webServer.user' frps.toml | grep -oP '"\K[^"]+' | head -1)
    DASHBOARD_PASS=$(grep 'webServer.password' frps.toml | grep -oP '"\K[^"]+' | head -1)
    AUTH_TOKEN=$(grep 'auth.token' frps.toml | grep -oP '"\K[^"]+' | head -1)
    # 提取允许的端口范围
    PORT_RANGE=$(grep -A3 'allowPorts' frps.toml | grep -oP 'start\s*=\s*\K\d+' | head -1)
    PORT_RANGE_END=$(grep -A3 'allowPorts' frps.toml | grep -oP 'end\s*=\s*\K\d+' | head -1)
else
    echo "警告: 配置文件 frps.toml 不存在，使用默认配置"
fi

# 检查服务状态
if docker ps 2>/dev/null | grep -q frps; then
    STATUS="✓ 运行中 (Docker)"
    RUN_MODE="docker"
elif [ -f frps.pid ] && kill -0 $(cat frps.pid) 2>/dev/null; then
    STATUS="✓ 运行中 (Binary, PID: $(cat frps.pid))"
    RUN_MODE="binary"
else
    STATUS="✗ 未运行"
    RUN_MODE="none"
fi

echo "【服务状态】"
echo "  $STATUS"
echo ""

echo "【Dashboard 管理界面】"
echo "  URL: http://${SERVER_IP}:${DASHBOARD_PORT:-7500}"
echo "  用户名: ${DASHBOARD_USER:-admin}"
echo "  密码: ${DASHBOARD_PASS:-your_frp_password_here}"
echo ""

echo "【客户端连接信息】"
echo "  服务器地址: ${SERVER_IP}:${BIND_PORT:-7000}"
echo "  认证 Token: ${AUTH_TOKEN:-your_frp_token_here}"
echo ""

echo "【允许端口范围】"
echo "  ${PORT_RANGE:-7001} - ${PORT_RANGE_END:-7010}"
echo ""

echo "【常用命令】"
if [ "$RUN_MODE" = "binary" ]; then
    echo "  启动: ./start.sh binary"
    echo "  停止: ./stop.sh binary"
    echo "  重启: ./restart.sh binary"
    echo "  查看日志: tail -f frps.log"
    echo "  切换 Docker: ./stop.sh binary && ./start.sh"
elif [ "$RUN_MODE" = "docker" ]; then
    echo "  启动: ./start.sh"
    echo "  停止: ./stop.sh"
    echo "  重启: ./restart.sh"
    echo "  查看日志: docker compose logs -f"
    echo "  切换 Binary: ./stop.sh && ./start.sh binary"
else
    echo "  Docker 方式:"
    echo "    启动: ./start.sh"
    echo "    停止: ./stop.sh"
    echo "    重启: ./restart.sh"
    echo ""
    echo "  Binary 方式:"
    echo "    启动: ./start.sh binary"
    echo "    停止: ./stop.sh binary"
    echo "    重启: ./restart.sh binary"
fi
echo ""

echo "【修改配置】"
echo "  配置文件: frps.toml"
echo "  或创建 .env 文件（推荐）:"
echo "    FRPS_DASHBOARD_USER=admin"
echo "    FRPS_DASHBOARD_PASSWORD=你的密码"
echo "    FRPS_AUTH_TOKEN=你的认证token"
echo "    FRPS_BIND_PORT=7000"
echo "    FRPS_DASHBOARD_PORT=7500"
echo "    FRPS_ALLOW_PORTS_START=7001"
echo "    FRPS_ALLOW_PORTS_END=7010"
echo ""

echo "【客户端配置示例 frpc.toml】"
echo "  serverAddr = \"${SERVER_IP}\""
echo "  serverPort = ${BIND_PORT:-7000}"
echo "  auth.method = \"token\""
echo "  auth.token = \"${AUTH_TOKEN:-your_frp_token_here}\""
echo ""

echo "【更多信息】"
echo "  查看完整文档: cat README.md"
echo "  客户端部署指南: 见客户端目录的 README.md"
echo ""
