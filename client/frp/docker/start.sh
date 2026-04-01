#!/bin/bash

cd "$(dirname "$0")"

# 加载配置
if [ -f .env ]; then
    source .env
fi

# 检查配置
if [ "$FRPS_SERVER" = "你的服务器IP" ] || [ -z "$FRPS_SERVER" ]; then
    echo "❌ 错误: 请先编辑 .env 文件，配置 FRPS_SERVER"
    exit 1
fi

if [ "$FRPS_TOKEN" = "your_frp_token_here" ] || [ -z "$FRPS_TOKEN" ]; then
    echo "❌ 错误: 请先编辑 .env 文件，配置 FRPS_TOKEN"
    echo "提示: 这个 Token 必须和服务器端的 FRPS_AUTH_TOKEN 一致"
    exit 1
fi

echo "启动 FRP 客户端..."
echo "服务器: $FRPS_SERVER:$FRPS_PORT"
echo "Token: ${FRPS_TOKEN:0:4}****"

# 如果使用配置文件模式
if [ "$USE_CONFIG_FILE" = "true" ]; then
    if [ ! -f "${FRPC_CONFIG_FILE:-frpc.toml}" ]; then
        echo "❌ 错误: 配置文件 ${FRPC_CONFIG_FILE:-frpc.toml} 不存在"
        echo "请先创建配置文件，或关闭 USE_CONFIG_FILE"
        exit 1
    fi
    echo "模式: 配置文件模式 (${FRPC_CONFIG_FILE:-frpc.toml})"
    # 配置文件模式下使用配置文件启动
    docker compose run -d --name ${CONTAINER_NAME:-frpc} --rm --network host \
        -v $(pwd)/${FRPC_CONFIG_FILE:-frpc.toml}:/etc/frp/frpc.toml:ro \
        snowdreamtech/frpc -c /etc/frp/frpc.toml 2>/dev/null || \
    docker-compose run -d --name ${CONTAINER_NAME:-frpc} --rm --network host \
        -v $(pwd)/${FRPC_CONFIG_FILE:-frpc.toml}:/etc/frp/frpc.toml:ro \
        snowdreamtech/frpc -c /etc/frp/frpc.toml
else
    echo "模式: 单隧道模式 (远程端口: $FRPC_REMOTE_PORT -> 本地端口: $FRPC_LOCAL_PORT)"
    # 检查单隧道配置
    if [ -z "$FRPC_REMOTE_PORT" ] || [ -z "$FRPC_LOCAL_PORT" ]; then
        echo "❌ 错误: 单隧道模式需要配置 FRPC_REMOTE_PORT 和 FRPC_LOCAL_PORT"
        exit 1
    fi
    # 构建命令行参数
    export FRPC_TUNNEL_ARGS="-p $FRPC_REMOTE_PORT -l $FRPC_LOCAL_PORT"
    docker compose up -d 2>/dev/null || docker-compose up -d
fi

echo ""
echo "✓ FRP 客户端已启动"
echo ""
echo "查看日志: docker logs -f ${CONTAINER_NAME:-frpc}"
