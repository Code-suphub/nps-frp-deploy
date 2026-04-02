#!/bin/bash

cd "$(dirname "$0")"

# 加载配置
if [ -f .env ]; then
    source .env
fi

# 检查配置
if [ "$NPS_SERVER" = "你的服务器IP:8024" ] || [ -z "$NPS_SERVER" ]; then
    echo "❌ 错误: 请先编辑 .env 文件，配置 NPS_SERVER"
    exit 1
fi

if [ "$NPS_VKEY" = "your_vkey_here" ] || [ -z "$NPS_VKEY" ]; then
    echo "❌ 错误: 请先编辑 .env 文件，配置 NPS_VKEY"
    echo "提示: 从 NPS Web 管理界面的「客户端」页面获取 vkey"
    exit 1
fi

# 检测操作系统和架构
if [ "$ARCH" = "auto" ] || [ -z "$ARCH" ]; then
    # 检测操作系统
    OS=$(uname -s)
    case $OS in
        Linux)
            OS_TYPE="linux"
            ;;
        Darwin)
            OS_TYPE="darwin"
            ;;
        MINGW*|CYGWIN*|MSYS*)
            OS_TYPE="windows"
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            echo "请手动设置 ARCH 变量，格式: {os}_{arch}"
            echo "可选: linux_amd64, linux_arm64, darwin_amd64, darwin_arm64, windows_amd64"
            exit 1
            ;;
    esac

    # 检测架构
    case $(uname -m) in
        x86_64|amd64)
            ARCH_TYPE="amd64"
            ;;
        aarch64|arm64)
            ARCH_TYPE="arm64"
            ;;
        armv7l)
            ARCH_TYPE="arm_v7"
            ;;
        *)
            echo "❌ 无法自动检测架构: $(uname -m)"
            echo "请手动设置 ARCH 变量，格式: {os}_{arch}"
            echo "可选: linux_amd64, linux_arm64, darwin_amd64, darwin_arm64, windows_amd64"
            exit 1
            ;;
    esac

    ARCH="${OS_TYPE}_${ARCH_TYPE}"
    echo "✓ 自动检测到系统: $OS ($ARCH)"
fi

# 检查二进制文件
if [ ! -f "$NPC_BINARY" ]; then
    echo "未找到 NPC 二进制文件，开始下载..."

    # 从 GitHub 下载最新版本
    DOWNLOAD_URL="https://github.com/ehang-io/nps/releases/download/v0.26.10/${ARCH}_client.tar.gz"

    echo "下载地址: $DOWNLOAD_URL"
    curl -L -o npc.tar.gz "$DOWNLOAD_URL"

    if [ $? -ne 0 ]; then
        echo "❌ 下载失败，请手动下载: https://github.com/ehang-io/nps/releases"
        exit 1
    fi

    echo "解压中..."
    tar -xzf npc.tar.gz
    rm -f npc.tar.gz

    # 设置可执行权限
    chmod +x npc

    echo "✓ 下载完成"
fi

echo ""
echo "启动 NPS 客户端..."
echo "服务器: $NPS_SERVER"
echo "VKey: ${NPS_VKEY:0:4}****"
echo ""

# 以后台方式运行
nohup ./npc -server="$NPS_SERVER" -vkey="$NPS_VKEY" -type="${NPS_TYPE:-tcp}" > npc.log 2>&1 &

echo $! > npc.pid
echo "✓ NPS 客户端已启动 (PID: $!)"
echo "日志文件: npc.log"
echo ""
echo "查看日志: tail -f npc.log"
echo "停止服务: ./stop.sh"
