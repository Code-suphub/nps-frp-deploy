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

# 检测架构
if [ "$ARCH" = "auto" ] || [ -z "$ARCH" ]; then
    case $(uname -m) in
        x86_64)
            ARCH="linux_amd64"
            ;;
        aarch64|arm64)
            ARCH="linux_arm64"
            ;;
        armv7l)
            ARCH="linux_arm_v7"
            ;;
        *)
            echo "❌ 无法自动检测架构: $(uname -m)"
            echo "请手动设置 ARCH 变量，可选: linux_amd64, linux_arm64, darwin_amd64, windows_amd64"
            exit 1
            ;;
    esac
    echo "✓ 自动检测到架构: $ARCH"
fi

# 检查二进制文件
if [ ! -f "$FRPC_BINARY" ]; then
    echo "未找到 FRPC 二进制文件，开始下载..."

    # 从 GitHub 下载最新版本
    DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v0.60.0/frp_0.60.0_${ARCH}.tar.gz"

    echo "下载地址: $DOWNLOAD_URL"
    curl -L -o frpc.tar.gz "$DOWNLOAD_URL"

    if [ $? -ne 0 ]; then
        echo "❌ 下载失败，请手动下载: https://github.com/fatedier/frp/releases"
        exit 1
    fi

    echo "解压中..."
    tar -xzf frpc.tar.gz --strip-components=1
    rm -f frpc.tar.gz

    # 设置可执行权限
    chmod +x frpc

    echo "✓ 下载完成"
fi

echo ""
echo "启动 FRP 客户端..."
echo "服务器: $FRPS_SERVER:$FRPS_PORT"
echo "Token: ${FRPS_TOKEN:0:4}****"

# 如果使用配置文件模式
if [ "$USE_CONFIG_FILE" = "true" ]; then
    if [ ! -f "${FRPC_CONFIG_FILE:-frpc.toml}" ]; then
        echo "❌ 错误: 配置文件 ${FRPC_CONFIG_FILE:-frpc.toml} 不存在"
        exit 1
    fi

    echo "模式: 配置文件模式 (${FRPC_CONFIG_FILE:-frpc.toml})"

    # 更新配置文件中的服务器信息
    sed -i "s/^serverAddr.*/serverAddr = \"$FRPS_SERVER\"/" "${FRPC_CONFIG_FILE:-frpc.toml}"
    sed -i "s/^serverPort.*/serverPort = $FRPS_PORT/" "${FRPC_CONFIG_FILE:-frpc.toml}"
    sed -i "s/^auth.token.*/auth.token = \"$FRPS_TOKEN\"/" "${FRPC_CONFIG_FILE:-frpc.toml}"

    # 启动
    nohup ./frpc -c "${FRPC_CONFIG_FILE:-frpc.toml}" > frpc.log 2>&1 &
else
    echo "模式: 单隧道模式 (远程端口: $FRPC_REMOTE_PORT -> 本地端口: $FRPC_LOCAL_PORT)"

    # 检查单隧道配置
    if [ -z "$FRPC_REMOTE_PORT" ] || [ -z "$FRPC_LOCAL_PORT" ]; then
        echo "❌ 错误: 单隧道模式需要配置 FRPC_REMOTE_PORT 和 FRPC_LOCAL_PORT"
        exit 1
    fi

    # 生成临时配置文件
    cat > /tmp/frpc_temp.toml << EOF
serverAddr = "$FRPS_SERVER"
serverPort = $FRPS_PORT
auth.method = "token"
auth.token = "$FRPS_TOKEN"

[[proxies]]
name = "tunnel"
type = "tcp"
localIP = "127.0.0.1"
localPort = $FRPC_LOCAL_PORT
remotePort = $FRPC_REMOTE_PORT
EOF

    # 启动
    nohup ./frpc -c /tmp/frpc_temp.toml > frpc.log 2>&1 &
fi

echo $! > frpc.pid
echo ""
echo "✓ FRP 客户端已启动 (PID: $!)"
echo "日志文件: frpc.log"
echo ""
echo "查看日志: tail -f frpc.log"
echo "停止服务: ./stop.sh"
